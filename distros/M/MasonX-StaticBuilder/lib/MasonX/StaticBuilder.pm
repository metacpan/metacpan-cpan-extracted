package MasonX::StaticBuilder;

use strict;
use warnings;

our $VERSION = '0.04';

use base qw(Class::Accessor);
MasonX::StaticBuilder->mk_accessors(qw(input_dir));

use Carp;
use File::Find::Rule;
use MasonX::StaticBuilder::Component;

=head1 NAME

MasonX::StaticBuilder -- Build a static website from Mason components

=head1 SYNOPSIS

    use MasonX::StaticBuilder;
    my $tree = MasonX::StaticBuilder->new($input_dir);
    $tree->write($output_dir, %args);

=head1 DESCRIPTION

Ever had to develop a website to deploy on a host that doesn't have
Mason?  I have.  The most crazy-making thing about it is that you
desparately want to use all the Mason tricks you're used to, but you
can't even do:

    <& header &>

AUGH!

Well, this fixes it.

Do your work in one directory, using whatever Mason stuff you want.
Then use MasonX::StaticBuilder to build a static website from it.

(Obviously you can also use this for non-web purposes.)

The following Mason features are tested and known to work in this
release:

=over 4

=item * 

Evaluation of expressions in <% %> 

=item * 

Args blocks

=item *

Init blocks

=item *

Inclusion of components using <& &>

=item *

Autohandlers

=back

The following are not known to work (and I'm not sure they even make
sense):

=over 4

=item *

dhandlers

=back

Anything not on that list means it's not something I regularly use, and
I don't have a test for it yet.  Additions to the test suite to cover
these other areas of Mason functionality are very welcome.

=head1 METHODS

=head2 new()

A simple constructor.  Pass it the directory where the components are to
be found.  

Note: if the directory doesn't exist, or whatever, this will return
undef.

=begin testing

use_ok('MasonX::StaticBuilder');
my $t = MasonX::StaticBuilder->new(".");
isa_ok($t, 'MasonX::StaticBuilder');
can_ok($t, qw(input_dir));

my $no = MasonX::StaticBuilder->new("this/directory/does/not/exist");
is($no, undef, "return undef if dir doesn't exist");

=end testing

=cut

sub new {
    my ($class, $input_dir) = @_;
    if ($input_dir && -e $input_dir && -d $input_dir) {
        $input_dir = File::Spec->rel2abs($input_dir);
        my $self = {};
        bless $self, $class;
        $self->input_dir($input_dir);
        return $self;
    } else {
        return undef;
    }
}

=head2 write()

Expand the template directory and write it out to the specified output
directory, passing any additional args to the mason components it finds.

=begin testing

my $t = MasonX::StaticBuilder->new("t/test-input-dir");
system "rm -rf t/test-output-dir";
mkdir("t/test-output-dir");
$t->write("t/test-output-dir", foo => "bar");

my %expected_contents = (
    simple => "bugger all",
    expr   => 42,
    args   => "Foo is bar",
    init   => "Baz is quux",
    "sub-component" => "bugger all",
    "autohandler-dir/ahtest" => "This is a header",
    "autohandler-dir/ahtest" => "autohandler goodness",
);

foreach my $file (sort keys %expected_contents) {
    my $fullfile = "t/test-output-dir/$file";
    open FILE, "<", $fullfile;
    local $/ = undef;
    my $file_contents = <FILE>;
    like(
        $file_contents,
        qr($expected_contents{$file}),
        "File $file expanded correctly."
    );
    close FILE;
}

=end testing

=cut

sub write {
    my ($self, $outdir, @args) = @_;
    my $rule = File::Find::Rule->file()
                        ->not_name("autohandler")
                        ->not_name("dhandler")
                        ->start($self->input_dir());
    while (my $c = $rule->match()) {
        next if $c =~ /\.svn/;
        my $comp_name = $self->_get_comp_name($c);
        my $component = MasonX::StaticBuilder::Component->new({
            comp_root => $self->input_dir(),
            comp_name => $comp_name,
        });

        my $output = $component->fill_in(@args);
        my $outfile = $outdir . $comp_name;

        # make sub-dirs if necessary
        if ($comp_name =~ m([^/]/[^/]) ) {
            my ($subdir, $file) = ($comp_name =~ m(^(.*)/(.*?)$));
            unless (-d "$outdir/$subdir") {
                if (mkdir("$outdir/$subdir")) {
                    $self->_write_file($outfile, $output);
                } else {
                    carp "Can't create required subdirectory $outdir/$subdir: $!";
                }
            }
        } else {
            $self->_write_file($outfile, $output);
        }
    }
}

sub _write_file {
    my ($self, $outfile, $output) = @_;
    open (OUT, ">", $outfile) or carp "Can't open output file $outfile: $!";
    print OUT $output;
    close OUT;
}

sub _get_comp_name {
    my ($self, $filename) = @_;
    my $comp_root = $self->input_dir();
    $filename =~ s/$comp_root//;
    return $filename;
}

=head1 BUGS

I haven't tested a wide range of Mason functionality, just the stuff I
regularly use.  Patches welcome.

The best way to report bugs on this software is vy the CPAN RT system at
http://rt.cpan.org/

=head1 AUTHOR

Kirrily Robert, skud@cpan.org

=head1 LICENSE

This module is distributed under the GPL/Artistic dual license, and may
be used under the same terms as Perl itself.

=cut

1;
