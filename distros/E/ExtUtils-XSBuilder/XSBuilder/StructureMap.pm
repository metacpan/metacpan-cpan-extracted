package ExtUtils::XSBuilder::StructureMap;

use strict;
use warnings FATAL => 'all';
use ExtUtils::XSBuilder::MapUtil qw(function_table structure_table);
use Data::Dumper ;

our @ISA = qw(ExtUtils::XSBuilder::MapBase);

sub new {
    my $class = shift;
    my $self = bless {wrapxs => shift}, $class;
    $self->{IGNORE_RE} = qr{^$};
    return $self ;
}

sub generate {
    my $self = shift;
    my $map = $self->get;

    for my $entry (@{ structure_table($self -> {wrapxs}) }) {
        my $type = $entry->{type};
        my $elts = $entry->{elts};

        next unless @$elts;
        next if $type =~ $self->{IGNORE_RE};
        next unless grep {
            not exists $map->{$type}->{ $_->{name} }
        } @$elts;

        print "<$type>\n";
        for my $e (@$elts) {
            print "   $e->{name}\n";
        }
        print "</$type>\n\n";
    }
}

sub disabled { shift->{disabled} }

sub check {
    my $self = shift;
    my $map = $self->get;

    my @missing;
    my $parsesource = $self -> {wrapxs} -> parsesource_objects ;

    loop:
    for my $entry (@{ structure_table($self -> {wrapxs}) }) {
        my $type = $entry->{type};

        for my $name (map $_->{name}, @{ $entry->{elts} }) {
            next if exists $map->{$type}->{$name};
            next if $type =~ $self->{IGNORE_RE};
            push @missing, "$type.$name";
        }
        push @missing, "$type.new" if (!exists $map->{$type}->{'new'}) ;
        push @missing, "$type.private" if (!exists $map->{$type}->{'private'}) ;
    }

    return @missing ? \@missing : undef;
}

sub check_exists {
    my $self = shift;

    my %structures;
    for my $entry (@{ structure_table($self -> {wrapxs}) }) {
        $structures{ $entry->{type} } = { map {
            $_->{name}, 1
        } @{ $entry->{elts} } };
    }

    my @missing;

    while (my($type, $elts) = each %{ $self->{map} }) {
        for my $name (keys %$elts) {
            next if exists $structures{$type}->{$name};
            push @missing, "$type.$name";
        }
    }

    return @missing ? \@missing : undef;
}

sub parse {
    my($self, $fh, $map) = @_;

    my($disabled, $class, $class2);
    my %cur;
    my %malloc;
    my %free;

    while ($fh->readline) {
        if (/MALLOC=\s*(.*?)\s*:\s*(.*?)$/) {
            $malloc{$1} = $2 ;
            next;
        }  
        if (/FREE=\s*(.*?)\s*:\s*(.*?)$/) {
            $free{$1} = $2 ;
            next;
        }  
        elsif (m:^(\W?)</([^>]+)>:) {
            $map->{$class}{-malloc} = { %malloc } ;
            $map->{$class}{-free}   = { %free } ;
            next;
        } 
        elsif (m:^(\W?)</?([^>]+)>:) {
            my $args;
            $disabled = $1;
            ($class, $args) = split /\s+/, $2, 2;
            if ($class eq 'struct')
                {    
                ($class2, $args) = split /\s+/, $args, 2;
                $class .= ' ' . $class2 ;
                }

            %cur = ();
            if ($args and $args =~ /E=/) {
                %cur = $self->parse_keywords($args);
            }

            $self->{MODULES}->{$class} = $cur{MODULE} if $cur{MODULE};

            next;
        }
        elsif (s/^(\w+):\s*//) {
            push @{ $self->{$1} }, split /\s+/;
            next;
        }

        if (s/^(\W)\s*// or $disabled) {
            my @parts = split /\s*\|\s*/ ;
            $map->{$class}->{$parts[0]} = undef;
            push @{ $self->{disabled}->{ $1 || '!' } }, "$class.$_";
        }
        else {
            my @parts = split /\s*\|\s*/ ;
            $map->{$class}->{$parts[0]} = { name      => $parts[0], 
                                            perl_name => $parts[1] || $parts[0],
                                            type      => $parts[2] } ;

        }
    }

    if (my $ignore = $self->{IGNORE}) {
        $ignore = join '|', @$ignore;
        $self->{IGNORE_RE} = qr{^($ignore)};
    }
    else {
        $self->{IGNORE_RE} = qr{^$};
    }
}

sub get {
    my $self = shift;

    $self->{map} ||= $self->parse_map_files;
}


sub write {
    my ($self, $fh, $newentries, $prefix) = @_ ;

    my $last = '' ;
    foreach my $type (@$newentries)
        {
        my ($struct, $elem) = split (/\./, $type) ;
        $fh -> print ("$prefix</$last>\n") if ($last && $last ne $struct) ;
        $fh -> print ("$prefix<$struct>\n") if ($last ne $struct) ;
        $last = $struct ;
        $fh -> print ($prefix, '  ', $self -> {wrapxs} -> mapline_elem ($elem), "\n") ;
        }
    $fh -> print ("$prefix</$last>\n") if ($last) ;
    }



1;
__END__
