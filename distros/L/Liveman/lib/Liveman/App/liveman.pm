package Liveman::App::liveman;
use 5.22.0;
use open qw/:std :utf8/;
use common::sense;

use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;
use Term::ANSIColor qw/:constants/;

use Liveman;

$| = 1;

my $parse_options_ok = GetOptions(
    'help|h'      => \( my $help = 0 ),
    'version|v'   => \( my $version = 0 ),
    'man'         => \( my $man  = 0 ),
    'O|options=s' => \( my $options ),
    'p|prove!'    => \( my $prove = 0 ),
    'o|open!'     => \( my $open = 0 ),
    'c|compile!'  => \( my $compile_only = 0 ),
    'f|force!'    => \( my $compile_force = 0 ),
    'a|append!'   => \( my $append = 0 ),
    'A|new!'      => \( my $project = 0 ),
    'D|cpanfile!' => \( my $cpanfile = 0 ),
    'd|diff_cpanfile:s' => \( my $diff_cpanfile ),
);

if ( !$parse_options_ok ) {
    pod2usage(2);
}
elsif ($help) {
    pod2usage(
        -input    => $INC{__PACKAGE__ =~ s/::/\//gr . ".pm"},
        -sections => "NAME|SYNOPSIS|DESCRIPTION|OPTIONS",
        -verbose  => 99
    );
}
elsif ($version) {
    print Liveman->VERSION, "\n";
}
elsif ($man) {
    pod2usage(
        -input   => $INC{__PACKAGE__ =~ s/::/\//gr . ".pm"},
        -exitval => 0,
        -verbose => 2,
    );
} elsif($project) {
    require Liveman::Project;
    Liveman::Project->new(pkg => $ARGV[0], license => $ARGV[1])->make;
}
elsif($append) {
    require Liveman::Append;
    my $liveman = Liveman::Append->new(files => \@ARGV)->appends;
    exit $liveman->{count} > 0? 0: 1;
}
elsif($cpanfile) {
    require Liveman::Cpanfile;
    print Liveman::Cpanfile->new->cpanfile;
}
elsif(defined $diff_cpanfile) {
	require File::Spec;
	require File::Slurper;
	require Liveman::Cpanfile;
    my $cpanfile = Liveman::Cpanfile->new->cpanfile;

    my $cpanfile_path = File::Spec->catfile(File::Spec->tmpdir, 'cpanfile');
    File::Slurper::write_text($cpanfile_path, $cpanfile);
    
    $diff_cpanfile ||= 'meld';

    my $res = system $diff_cpanfile, $cpanfile_path, 'cpanfile';
    print "$diff_cpanfile failed\n" if $res;
    exit $res;
}
else {
    my $liveman = Liveman->new(
        files => \@ARGV,
        options => $options,
        prove => $prove,
        open => $open,
        compile_force => $compile_force,
    );
    $liveman->transforms;
    exit 0 if $compile_only;
    exit $liveman->tests->{exit_code};
}

1;

__END__

=encoding utf-8

=head1 NAME

"Liveman - “Living Guide”. Utility for converting files B<lib/**.md> in test files (B<t/**.t>) and documentation (B<POD>), which is placed in the corresponding module (B<lib/**.pm>)

=head1 SYNOPSIS

	liveman [-h] [--man] [-A pkg [license]] [-w] [-o][-c][-f][-s][-a] [<files> ...]

=head1 DESCRIPTION

The problem of modern projects is that the documentation is separated from testing.
This means that the examples in the documentation may not work, and the documentation itself can lag behind the code.

The method of simultaneous documentation and testing solves this problem.

For the documentation, the B<md> format was selected, since it is the most simple for input and widespread.
The areas of code B<perl> described in it are broadcast into a test. The documentation is translated into B<pod> and is added to the B<__END__> section of the perl module.

In other words, B<liveman> converts B<lib/**.md>-files to test files (B<t/**.t>) and documentation that is placed in the corresponding B<lib/**.pm> module. And immediately launches the tests with coating.

The coating can be viewed in the I<*cover_db/coverage.html> file.

Note: it is better to immediately place I<cover_db/> in I<.gitignore>.

=head1 OPTIONS

B<-h>, B<--help>

Show a certificate and get out.

B<-v>, B<--version>

Show the version and go out.

	`perl $ENV{PROJECT_DIR}/script/liveman -v` # ~> ^\d+\.\d+$

B<--man>

Print instructions and end.

B<-c>, B<--compile>

Only compile (without starting the tests).

B<-f>, B<--force>

Convert the I<lib/**.md> files, even if they have not changed.

B<-p>, B<--prove>

Use the C<prove> utility for tests, not C<yath>.

B<-o>, B<--open>

Open the coating in the browser.

B<-O>, B<--options> OPTIONS

Transfer the line with the options C<yath> or C<prove>. These parameters will be added to the default parameters.

Default parameters for C<yath>:

 C<yath test -j4 --cover>

Default parameters for C<prove>:

 C<prove -Ilib -r t>

B<-a>, B<--append>

Add functions in C<*.md> fromC<*.pm> and end.

B<-A>, B<--new> PACKAGE [LICENSE]

Create a new repository.

=over

=item * I<PACKAGE> - this is the name of the new package, for example, C<Aion::View>.

=item * I<License> is a license name, for example, GPLv3 or perl_5.

=back

B<-D>, B<--cpanfile>

Print a sample cpanfile.

B<-d>, B<--diff-cpanfile> [meld]

Compare the sample cpanfile with the existing one. If the parameter is not specified, C<meld> is used. Alternatively, you can use C<diff>, C<colordiff>, C<wdiff>, C<kompare>, C<kdiff3>, C<tkdiff>, C<diffuse> or any other utility that takes two files as arguments.

=head1 INSTALL

To install this module in your system, follow the following L<App::cpm>

	sudo cpm install -gvv Liveman

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The App::Liveman module is Copyright © 2024 Yaroslav O. Kosmina. Rusland. All Rights Reserved.
