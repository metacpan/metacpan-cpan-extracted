package Dist::Maker::Template::CLI;
use utf8;
use Mouse;
use MouseX::StrictConstructor;

extends 'Dist::Maker::Template::Default';
with    'Dist::Maker::Template';

sub distribution {
    return <<'DIST';
: cascade Default;

:# @@ Makefile.PL

: after mpl_requires {
requires 'Getopt::Long' => '2.37';
: }

: after mpl_footer {
install_script '<: $dist.moniker :>';
: }

:# @@ lib/$dist.module_path
: after module_code -> {
use Getopt::Long ();

sub getopt_spec {
    return(
        'version',
        'help',
    );
}

sub getopt_parser {
    return Getopt::Long::Parser->new(
        config => [qw(
            no_ignore_case
            bundling
            no_auto_abbrev
        )],
    );
}

sub appname {
    my($self) = @_;
    require File::Basename;
    return File::Basename::basename($0);
}

sub new {
    my $class = shift;
    local @ARGV = @_;

    my %opts;
    my $success = $class->getopt_parser->getoptions(
        \%opts,
        $class->getopt_spec());

    if(!$success) {
        $opts{help}++;
        $opts{getopt_failed}++;
    }

    $opts{argv} = \@ARGV;

    return bless \%opts, $class;
}

sub run {
    my $self = shift;

    if($self->{help}) {
        $self->do_help();
    }
    elsif($self->{version}) {
        $self->do_version();
    }
    else {
        $self->dispatch(@ARGV);
    }

    return;
}

sub dispatch {
    my($self, @args) = @_;
    print Dump($self);
    return;
}

sub Dump {
    my($data, $name) = @_;
    require Data::Dumper;
    my $dd = Data::Dumper->new([$data], [$name || 'app']);
    $dd->Indent(1);
    $dd->Maxdepth(3);
    $dd->Quotekeys(0);
    $dd->Sortkeys(1);
    return $dd->Dump();
}

sub do_help {
    my($self) = @_;
    if($self->{getopt_failed}) {
        die $self->help_message();
    }
    else {
        print $self->help_message();
    }
}

sub do_version {
    my($self) = @_;
    print $self->version_message();
}

sub help_message {
    my($self) = @_;
    require Pod::Usage;

    open my $fh, '>', \my $buffer;
    Pod::Usage::pod2usage(
        -message => $self->version_message(),
        -exitval => 'noexit',
        -output  => $fh,
        -input   => __FILE__,
    );
    close $fh;
    return $buffer;
}

sub version_message {
    my($self) = @_;

    require Config;
    return sprintf "%s\n" . "\t%s/%s\n" . "\tperl/%vd on %s\n",
        $self->appname(), ref($self), $VERSION,
        $^V, $Config::Config{archname};
}
: } # module_code

: override synopsis {
    $ <: $dist.moniker :> --help
: }

: override basic_t_tests -> {
my $app = <: $dist.module :>->new('--version');

my $help = $app->help_message;
note $help;
ok $help, 'help_message';

ok $app->appname,         'appname';
ok $app->version_message, 'version_message';

my $v = do {
    open my $fh, '>', \my $buffer;
    local *STDOUT = $fh;
    $app->run(); # do version
    $buffer;
};
like $v, qr/perl/;

my $x = `$^X -Ilib script/<: $dist.moniker :> --version`;
like $x, qr/perl/, 'exec <: $dist.moniker :> --version';

: }

: override podcoverage_t { } # nothing
: override podsynopsis_t { } # nothing

: after extra_files -> {
@@ script/<: $dist.moniker :>
#!perl
use strict;
use warnings;
use <: $dist.module :>;

my $app = <: $dist.module :>->new(@ARGV);
$app->run();
__END__

=head1 DESCRIPTION

See L<<: $dist.module :>>.

=cut
: } # extra_files
DIST
}

no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Dist::Maker::Template::CLI - Distribution template for CLI applications

=cut
