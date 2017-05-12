=head1 NAME

DynGig::Util::CLI - An easy-to-print CLI menu for Getopt

=cut
package DynGig::Util::CLI;

use warnings;
use strict;

=head1 SYNOPSIS

 use DynGig::Util::CLI;
 use Getopt::Long;
 
 my %o = ( s => 30, link => 'current' );

 my $menu = DynGig::Util::CLI->new
 (
     'h|help',"print help menu",
     's|sleep=i',"[ $o{s} ] seconds between iterations",
     'link=s',"[ $o{link} ] symlink to current config",
     'server=s','server host:port',
 );

 my @option = $menu->option();
 my $string = $menu->string();

 die join "\n", "Usage:\tdefault value in [ ]", $string, "\n"
     unless Getopt::Long::GetOptions( \%o, @option ) && ! $o{h};

=cut
sub new
{
    my $class = shift @_;
    my ( @max, @menu, @option );
    my $max = 1;

    for ( my $i = 0; $i < @_; $i++ )
    {
        my $key = $_[$i];
        my @key = split /\|/, ( split( /[=!+:]/o, $key, 2 ) )[0];

        $max = @key if $max < @key;
        push @option, $key;
        push @menu, [ \@key, $_[++ $i] ];
    }

    for my $m ( @menu )
    {
        my $key = $m->[0];

        for ( my $i = @$key; $i < $max; $i ++ ) { unshift @$key, '' }
        for ( my $i = 0; $i < $max; $i ++ )
        {
            my $len = $m->[2][$i] = length $key->[$i];
            $max[$i] = $len unless $max[$i] && $max[$i] > $len;
        }
    }

    for my $m ( @menu )
    {
        my $key = $m->[0];

        for ( my $i = 0, my $len = pop @$m; $i < $max; $i ++ )
        {
            my $len = $len->[$i];
            my $wall = $len ? '|' : ' ';
            my $dash = $len > 1 ? '--' : $len ? ' -' : '  ';
            $key->[$i] = sprintf $dash.'%-'.$max[$i].'s%2s',
                $key->[$i], $wall;
        }

        $m->[0] = join ' ', @$key;
        chop $m->[0];
    }

    my $string = join "\n ", map { join ' ', @$_ } [], @menu;
    bless { string => $string, option => \@option  }, ref $class || $class;
}

=head2 option()

Returns menu options as a list. Returns ARRAY reference in scalar context.

=head2 string()

Serializes menu.

=cut
sub AUTOLOAD
{
    my $this  = shift @_;
    my $field = our $AUTOLOAD =~ /::(\w+)$/ ? $this->{$1} : undef;
    return wantarray && ref $field eq 'ARRAY' ? @$field : $field;
}

sub DESTROY
{
    my $this = shift;
    map { delete $this->{$_} } keys %$this;
}

=head1 NOTE

See DynGig::Util

=cut

1;

__END__
