package ExtUtils::XSBuilder::FunctionMap;

use strict;
use warnings FATAL => 'all';
use ExtUtils::XSBuilder::MapUtil qw(function_table structure_table);
use Data::Dumper ;

our @ISA = qw(ExtUtils::XSBuilder::MapBase);

sub new {
    my $class = shift;
    bless {wrapxs => shift}, $class;
}

#for adding to function.map
sub generate {
    my $self = shift;

    my $missing = $self->check;
    return unless $missing;

    print " $_\n" for @$missing;
}

sub disabled { shift->{disabled} }

#look for functions that do not exist in *.map
sub check {
    my $self = shift;
    my $map = $self->get;

    my @missing;
    my $parsesource = $self -> {wrapxs} -> parsesource_objects ;

    loop:
    for my $name (map $_->{name}, @{ function_table($self -> {wrapxs}) }) {
        next if exists $map->{$name};
        #foreach my $obj (@$parsesource)
        #    {
        #    next loop if ($obj -> handle_func ($name)) ;
        #    }
        push @missing, $name ;
    }

    return @missing ? \@missing : undef;
}

#look for functions in *.map that do not exist
my $special_name = qr{(^DEFINE_|DESTROY$)};

sub check_exists {
    my $self = shift;

    my %functions = map { $_->{name}, 1 } @{ function_table($self -> {wrapxs}) };
    my @missing = ();

    for my $name (keys %{ $self->{map} }) {
        next if $functions{$name};
        push @missing, $name unless $name =~ $special_name;
    }

    return @missing ? \@missing : undef;
}

my $keywords = join '|', qw(MODULE PACKAGE PREFIX BOOT);



sub class_c_prefix {
    my $self = shift;
    my $class = shift;
    $class =~ s/:/_/g;
    $class;
}

sub class_xs_prefix {
    my $self = shift;
    my $class = shift;
    my $class_prefix = $self -> class_c_prefix($class);
    return $self -> {wrapxs} -> my_xs_prefix . $class_prefix . '_' ;
}

sub needs_prefix {
    my $self = shift;
    my $name = shift;
    $self -> {wrapxs} -> needs_prefix ($name) ;
}

sub make_prefix {
    my($self, $name, $class) = @_;
    my $class_prefix = $self -> class_xs_prefix($class);
    return $name if $name =~ /^$class_prefix/;
    $class_prefix . $name;
}


sub guess_prefix {
    my $self = shift;
    my $entry = shift;

    my($name, $class) = ($entry->{name}, $entry->{class});
    my $prefix = "";
    my $myprefix = $self -> {wrapxs} -> my_xs_prefix ;
    $name =~ s/^DEFINE_//;
    $name =~ s/^$myprefix//i;

    (my $guess = lc($entry->{class} || $entry->{module}) . '_') =~ s/::/_/g;
    $guess =~ s/(apache)_/($1|ap)_{1,2}/;

    if ($name =~ s/^($guess).*/$1/i) {
        $prefix = $1;
    }
    else {
        if ($name =~ /^(apr?_)/) {
            $prefix = $1;
        }
    }

    #print "GUESS prefix=$guess, name=$entry->{name} -> $prefix\n";

    return $prefix;
}

sub parse {
    my($self, $fh, $map) = @_;
    my %cur;
    my $disabled = 0;

    while ($fh->readline) {
        if (/($keywords)=/o) {
            $disabled = s/^\W//; #module is disabled
            my %words = $self->parse_keywords($_);

            if ($words{MODULE}) {
                %cur = ();
            }

            if ($words{PACKAGE}) {
                delete $cur{CLASS};
            }

            for (keys %words) {
                $cur{$_} = $words{$_};
            }

            next;
        }

        my($name, $dispatch, $argspec, $alias) = split /\s*\|\s*/;

        my $dispatch_argspec = '' ; 

        if ($dispatch && ($dispatch =~ m#\s*(.*?)\s*\((.*)\)#))
            {
            $dispatch = $1; 
            $dispatch_argspec = $2; 
            }

        my $return_type;

        if ($name =~ s/^([^:]+)://) {
            $return_type = $1;
        }

        if ($name =~ s/^(\W)// or not $cur{MODULE} or $disabled) {
            #notimplemented or cooked by hand
            $map->{$name} = undef;
            push @{ $self->{disabled}->{ $1 || '!' } }, $name;
            next;
        }

        if (my $package = $cur{PACKAGE}) {
            unless ($package eq 'guess') {
                $cur{CLASS} = $package;
            }
            if ($cur{ISA}) {
                $self->{isa}->{ $cur{MODULE} }->{$package} = delete $cur{ISA};
            }
            if ($cur{BOOT}) {
                $self->{boot}->{ $cur{MODULE} } = delete $cur{BOOT};
            }
        }
        else {
            $cur{CLASS} = $cur{MODULE};
        }

        if ($name =~ /^DEFINE_/ and $cur{CLASS}) {
            $name =~ s{^(DEFINE_)(.*)}
              {$1 . $self->make_prefix($2, $cur{CLASS})}e;
        print "DEFINE $name arg=$argspec\n" ;
	}

        my $entry = $map->{$name} = {
           name        => $alias || $name,
           dispatch    => $dispatch,
           dispatch_argspec    => $dispatch_argspec,
           argspec     => $argspec ? [split /\s*,\s*/, $argspec] : "",
           return_type => $return_type,
           alias       => $alias,
        };

        for (keys %cur) {
            $entry->{lc $_} = $cur{$_};
        }

        #avoid 'use of uninitialized value' warnings
        $entry->{$_} ||= "" for keys %{ $entry };
        if ($entry->{dispatch} =~ /_$/) {
            $entry->{dispatch} .= $name;
        }
    }
}

sub get {
    my $self = shift;

    $self->{map} ||= $self->parse_map_files;
}

sub prefixes {
    my $self = shift;
    $self = ExtUtils::XSBuilder::FunctionMap->new unless ref $self;

    my $map = $self->get;
    my %prefix;

    while (my($name, $ent) = each %$map) {
        next unless $ent->{prefix};
        $prefix{ $ent->{prefix} }++;
    }

    $prefix{$_} = 1 for qw(ap_ apr_); #make sure we get these

    [keys %prefix]
}


sub write {
    my ($self, $fh, $newentries, $prefix) = @_ ;

    foreach (@$newentries)
        {
        $fh -> print ($prefix, $self -> {wrapxs} -> mapline_func ($_), "\n") ;
        }
    }

1;
__END__
