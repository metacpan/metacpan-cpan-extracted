package MVC::Neaf::CLI;

use strict;
use warnings;
our $VERSION = 0.2202;

=head1 NAME

MVC::Neaf::CLI - Command line debugger and runner for Not Even A Framework

=head1 DESCRIPTION

Run your applications from command line, with various overrides.

May be useful for command-line mode debugging (think CGI.pm)
as well as starting the app from command line.

=head1 SYNOPSIS

    perl application.pl --list

Print routes defined in the application.

    perl application.pl --post /foo/bar arg=42

Simulate a request without running a server.

    perl application.pl --listen :5000

Run a psgi server.

=head1 OPTIONS

=over

=item * --help - display a brief usage message.

=item * --list - print routes configured in the application.

=item * --listen <port-or-socket> - start application as a standalone
plack  servers. Any subsequent options compatible with plackup(1)
are allowed in this mode.

=item * --post - set method to POST.

=item * --method METHOD - set method to anything else.

=item * --upload id=/path/to/file - add upload. Requires --post.

=item * --cookie name="value" - add cookie.

=item * --header name="value" - set http header.

=item * --view - force (JS,TT,Dumper) view.


=back

=head2 METHODS

The usage doesn't expect these are called directly.

But just for the sake of completeness...

=cut

use Getopt::Long;
use Carp;
use HTTP::Headers::Fast;
use File::Basename qw(basename);

use MVC::Neaf;
use MVC::Neaf::Upload;

=head2 run( $app )

Run the application.
This reads command line options, as shown in the summary above.

$app is an MVC::Neaf object.

B<NOTE> Spoils @AGRV.

=cut

sub run {
    my ($self, $app) = @_;

    my %test;

    if (grep { $_ eq '--list' } @ARGV) {
        return $self->list($app);
    };
    if (grep { $_ eq '--help' } @ARGV) {
        return usage();
    };

    # TODO 0.30 --view here so that view is forced in both modes
    if (grep { $_ =~ /^--listen/ } @ARGV) {
        return $self->serve( $app );
    };

    GetOptions(
        "post"       => sub { $test{method} = 'POST' },
        "method=s"   => \$test{method},
        "upload=s@"  => \$test{upload},
        "cookie=s@"  => \$test{cookie},
        "header=s@"  => \$test{head},
        "view=s"     => \$test{view},
        # TODO 0.30 --session to reduce hassle
    ) or croak "Bad command line options in MVC::Neaf::CLI, see $0 --help";

    return $self->run_test($app, %test);
};

=head2 serve( $app, @arg )

Use L<Plack::Runner> to start server.

=cut

sub serve {
    my ($self, $app) = @_;

    require Plack::Runner;
    my $runner = Plack::Runner->new;
    $runner->parse_options( @ARGV );
    $runner->run( $app->run );
    exit;
};

=head2 run_test( $app, %override )

Call L<MVC::Neaf>'s C<run_test>.

=cut

sub run_test {
    my ($self, $app, %test) = @_;

    $test{method} = uc $test{method} if $test{method};

    croak "--upload requires --post"
        if $test{upload} and $test{method} ne 'POST';

    if (my $up =  delete $test{upload}) {
        foreach (@$up) {
            /^(\w+)=(.+)$/ or croak "Usage: --upload key=/path/to/file";
            my ($key, $file) = ($1, $2);

            open my $fd, "<", $file
                or die "Failed to open upload $key file $file: $!";

            # TODO 0.30 create temp file
            $test{uploads}{$key} = MVC::Neaf::Upload->new(
                id => $key, handle => $fd, filename => $file );
        };
    };

    if (my $cook = delete $test{cookie}) {
        foreach (@$cook) {
            /^(\w+)=(.*)$/
                or croak "Usage: --cookie name=value";
            $test{cookie}{$1} = $2;
        };
    };

    if (my @head = @{ delete $test{head} || [] }) {
        $test{header_in} = HTTP::Headers::Fast->new (
            map { /^([^=]+)=(.*)$/ or croak "Bad header format"; $1=>$2 } @head
        );
    };

    my ($path, @rest) = @ARGV;
    $path ||= '/';
    if (@rest) {
        my $sep = $path =~ /\?/ ? '&' : '?';
        $path .= $sep . join '&', @rest;
    };

    if (my $view = delete $test{view}) {
        $app->set_forced_view( $view );
    };

    my ($status, $head, $content) = $app->run_test( $path, %test );

    print STDOUT "Status $status\n";
    print STDOUT $head->as_string, "\n";
    print STDOUT $content;
    # exit?
};

=head2 usage()

Display help message and exit(0).

B<NOTE> exit() used.

=cut

sub usage {
    my $script = basename($0);

    print <<"USAGE";
    $script
is a web-application powered by Perl and MVC::Neaf (Not Even A Framework).
It will behave according to the CGI spec if run without parameters.
It will return a PSGI-compliant subroutine if require'd from other Perl code.
To run it as a standalone server, use --listen switch along with any
other switches recognized by plackup(1)
    perl $script --listen :31415 <...>
To peek at the application, run
    perl $script --list
To get this summary, run
    perl $script --help
To invoke debugging mode, run:
    perl $script [options] [/path] <param=value> ...
Options may include:
    --post - force request method to POST
    --method METHOD - force method to anything else
    --upload id=/path/to/file - add upload. Requires --post.
    --cookie name="value" - add cookie.
    --header name="value" - set http header.
    --view - force (JS,TT,Dumper) view.
See `perldoc MVC::Neaf::CLI` for more.
USAGE

    exit 0; # Yes, MVC::Neaf::CLI->usage() will exit deliberately.
};

=head2 list()

List registered Neaf routes.

=cut

sub list {
    my ($self, $app) = @_;

    my %inverse_descr; # {path+printable descr} = [method, method]

    my $routes = $app->get_routes( sub {
        my ($route, $path, $method) = @_;

        my @features;
        if ( my $rex = $route->{path_info_regex} ) {
            $rex = "$rex";
            $rex =~ m#^\(.*?\((.*)\).*?\)$# and $rex = $1;
            push @features, "/$rex"
        };
        my $param = join "&", map { "$_=$route->{param_regex}{$_}" }
            sort keys %{ $route->{param_regex} };
        push @features, "?$param" if $param;

        push @features, " # $route->{description}"
            if $route->{description};

        my $descr = join "", $path, @features;

        push @{ $inverse_descr{$descr} }, $method;
    } );

    # Convert available methods to printable format
    $_ = join ",", sort @$_ for values %inverse_descr;

    foreach (sort keys %inverse_descr) {
        printf "[%s] %s\n", $inverse_descr{$_}, $_;
    };
};

1;


