package Getopt::EX::Long;
use version; our $VERSION = version->declare("v1.25.1");

use v5.14;
use warnings;
use Carp;

*REQUIRE_ORDER   = \$Getopt::Long::REQUIRE_ORDER;
*PERMUTE         = \$Getopt::Long::PERMUTE;
*RETURN_IN_ORDER = \$Getopt::Long::RETURN_IN_ORDER;

*Configure       = \&Getopt::Long::Configure;
*HelpMessage     = \&Getopt::Long::HelpMessage;
*VersionMessage  = \&Getopt::Long::VersionMessage;

use Exporter 'import';
our @EXPORT    = qw(&GetOptions $REQUIRE_ORDER $PERMUTE $RETURN_IN_ORDER);
our @EXPORT_OK = ( '&GetOptionsFromArray',
		 # '&GetOptionsFromString',
		   '&Configure',
		   '&HelpMessage',
		   '&VersionMessage',
		   '&ExConfigure',
    );
our @ISA       = qw(Getopt::Long);

use Data::Dumper;
use Getopt::Long();
use Getopt::EX::Loader;
use Getopt::EX::Func qw(parse_func);

my %ConfigOption = ( AUTO_DEFAULT => 1 );
my @ValidOptions = ('AUTO_DEFAULT' , @Getopt::EX::Loader::OPTIONS);

my $loader;

sub GetOptions {
    unshift @_, \@ARGV;
    goto &GetOptionsFromArray;
}

sub GetOptionsFromArray {
    my $argv = $_[0];

    set_default() if $ConfigOption{AUTO_DEFAULT};

    $loader //= Getopt::EX::Loader->new(do {
	map {
	    exists $ConfigOption{$_} ? ( $_ => $ConfigOption{$_} ) : ()
	} @Getopt::EX::Loader::OPTIONS
    });

    $loader->deal_with($argv);

    my @builtins = do {
	if (ref $_[1] eq 'HASH') {
	    $loader->hashed_builtins($_[1]);
	} else {
	    $loader->builtins;
	}
    };
    push @_, @builtins;

    goto &Getopt::Long::GetOptionsFromArray;
}

sub GetOptionsFromString {
    die "GetOptionsFromString is not supported, yet.\n";
}

sub ExConfigure {
    my %opt = @_;
    for my $name (@ValidOptions) {
	if (exists $opt{$name}) {
	    $ConfigOption{$name} = delete $opt{$name};
	}
    }
    warn "Unknown option: ", Dumper \%opt if %opt;
}

sub set_default {
    use List::Util qw(pairmap);
    pairmap { $ConfigOption{$a} //= $b } get_default();
}

sub get_default {
    my @list;

    my $prog = ($0 =~ /([^\/]+)$/) ? $1 : return ();

    if (defined (my $home = $ENV{HOME})) {
	if (-f (my $rc = "$home/.${prog}rc")) {
	    push @list, RCFILE => $rc;
	}
    }

    push @list, BASECLASS => "App::$prog";

    @list;
}

1;

############################################################

package Getopt::EX::Long::Parser;

use strict;
use warnings;

use List::Util qw(first);
use Data::Dumper;

use Getopt::EX::Loader;

our @ISA = qw(Getopt::Long::Parser);

sub new {
    my $class = shift;

    my @exconfig;
    while (defined (my $i = first { $_[$_] eq 'exconfig' } 0 .. $#_)) {
	push @exconfig, @{ (splice @_, $i, 2)[1] };
    }
    if (@exconfig == 0 and $ConfigOption{AUTO_DEFAULT}) {
	@exconfig = Getopt::EX::Long::get_default();
    }

    my $obj = $class->SUPER::new(@_);

    my $loader = $obj->{exloader} = Getopt::EX::Loader->new(@exconfig);

    $obj;
}

sub getoptionsfromarray {
    my $obj = shift;
    my $argv = $_[0];
    my $loader = $obj->{exloader};

    $loader->deal_with($argv);

    my @builtins = do {
	if (ref $_[1] eq 'HASH') {
	    $loader->hashed_builtins($_[1]);
	} else {
	    $loader->builtins;
	}
    };
    push @_, @builtins;

    $obj->SUPER::getoptionsfromarray(@_);
}

1;

=head1 NAME

Getopt::EX::Long - Getopt::Long compatible glue module

=head1 SYNOPSIS

  use Getopt::EX::Long;
  GetOptions(...);

  or

  require Getopt::EX::Long;
  my $parser = Getopt::EX::Long::Parser->new(
	config   => [ Getopt::Long option ... ],
	exconfig => [ Getopt::EX::Long option ...],
  );

=head1 DESCRIPTION

L<Getopt::EX::Long> is almost compatible to L<Getopt::Long> and you
can just replace module declaration and it should work just same as
before (See L<INCOMPATIBILITY> section).

Besides working same, user can define their own option aliases and
write dynamically loaded extension module.  If the command name is
I<example>,

    ~/.examplerc

file is loaded by default.  In this rc file, user can define their own
option with macro processing.  This is useful when the command takes
complicated arguments.

Also, special command option preceded by B<-M> is taken and
corresponding perl module is loaded.  Module is assumed under the
specific base class.  For example,

    % example -Mfoo

will load C<App::example::foo> module, by default.

This module is normal perl module, so user can write any kind of
program.  If the module is specified with initial function call, it is
called at the beginning of command execution.  Suppose that the
module I<foo> is specified like this:

    % example -Mfoo::bar(buz=100) ...

Then, after the module B<foo> is loaded, function I<bar> is called
with the parameter I<baz> which has value 100.

If the module includes C<__DATA__> section, it is interpreted just
same as rc file.  So you can define arbitrary option there.  Combined
with startup function call described above, it is possible to control
module behavior by user defined option.

As for start-up file and Module specification, read
L<Getopt::EX::Module> document for detail.

=head1 CONFIG OPTIONS

Config options are set by B<Getopt::ExConfigure> or B<exconfig>
parameter for B<Getopt::EX::Long::Parser::new> method.

=over 4

=item AUTO_DEFAULT

Config option B<RCFILE> and B<BASECLASS> are automatically set based
on the name of command executable.  If you don't want this behavior,
set B<AUTO_DEFAULT> to 0.

=back

Other options including B<RCFILE> and B<BASECLASS> are passed to
B<Getopt::EX::Loader>.  Read its document for detail.

=head1 INCOMPATIBILITY

Subroutine B<GetOptionsFromString> is not supported.

=head1 SEE ALSO

L<Getopt::EX>,
L<Getopt::EX::Module>
