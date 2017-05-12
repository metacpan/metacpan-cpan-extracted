package ExtUtils::XSBuilder::CallbackMap;

use strict;
use warnings FATAL => 'all';
use ExtUtils::XSBuilder::MapUtil qw(callback_table);

our @ISA = qw(ExtUtils::XSBuilder::FunctionMap);

# ============================================================================

#look for callbacks that do not exist in *.map
sub check {
    my $self = shift;
    my $map = $self->get;

    my @missing;
    my $parsesource = $self -> {wrapxs} -> parsesource_objects ;

    loop:
    for my $name (map $_->{name}, @{ callback_table($self -> {wrapxs}) }) {
        next if exists $map->{$name};
        push @missing, $name ;
    }

    return @missing ? \@missing : undef;
}

# ============================================================================

#look for callbacks in *.map that do not exist

sub check_exists {
    my $self = shift;

    my %callbacks = map { $_->{name}, 1 } @{ callback_table($self -> {wrapxs}) };
    my @missing = ();

    #print Data::Dumper -> Dump ([\%callbacks, $self->{map}]) ;

    for my $name (keys %{ $self->{map} }) {
        next if $callbacks{$name};
        push @missing, $name ;
    }

    return @missing ? \@missing : undef;
}


# ============================================================================

sub parse {
    my($self, $fh, $map) = @_;
    my %cur;
    my $disabled = 0;

    while ($fh->readline) {
        my($type, $argspec) = split /\s*\|\s*/;

        my $entry = $map->{$type} = {
           name        => $type,
           argspec     => $argspec ? [split /\s*,\s*/, $argspec] : "",
        };


        #avoid 'use of uninitialized value' warnings
        $entry->{$_} ||= "" for keys %{ $entry };
    }
}



sub write {
    my ($self, $fh, $newentries, $prefix) = @_ ;

    foreach (@$newentries)
        {
        my $line = $self -> {wrapxs} -> mapline_func ($_) ;

        if ($line =~ /\)\((.*?)\)/)
            {
            my @args = split (/,/, $1) ;
            $line .= ' | ' if (@args) ;
            my $i = 0 ;
            foreach (@args)
                {
                $line .= ',' if ($i++ > 0) ;
                /([^ ]+)$/ ;
                my $arg = $1 ;
                $line .= '<' if (/\* \*/) ;
                $line .= $arg ;
                }
            }
        
        $fh -> print ($prefix, $line, "\n") ;
        }
    }

