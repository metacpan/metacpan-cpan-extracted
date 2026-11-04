package TestDiscordExamples;

use v5.26;
use warnings;
use Exporter 'import';
use File::Spec;
use Scalar::Util qw(blessed);
use Discord::Client;

our @EXPORT_OK = qw(load_example);

sub load_example {
    my ( $path, %options ) = @_;
    my $constructor = Discord::Client->can('new');

    # Exercise the real script while injecting controlled public SDK dependencies.
    my $bot;
    {
        no warnings 'redefine';
        local *Discord::Client::new = sub {
            my ( $class, %arguments ) = @_;
            return $constructor->( $class, %arguments, %options );
        };
        $bot = do File::Spec->rel2abs($path);
    }

    # Restore the constructor before inspecting the example's returned client.
    die "Could not load example $path: $@ $!"
        unless blessed($bot) && $bot->isa('Discord::Client');
    return $bot;
}

1;
