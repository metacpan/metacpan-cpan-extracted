
=head1 NAME

File::Corresponding::File::Profile - The definition of what matches
and translates to corresponding files

=cut

use strict;
package File::Corresponding::File::Profile;
$File::Corresponding::File::Profile::VERSION = '0.004';
use Moose;

use Moose::Util::TypeConstraints;
use Data::Dumper;
use Path::Class;

use File::Corresponding::File::Found;



=head1 PROPERTIES

=head2 name

Name/description of this file profile.

=cut
has 'name' => (is => 'ro', isa => 'Str', default => "");




=head2 sprintf

sprintf string to construct a file name. It should contain at least
one % command to insert a relative file name.

Only used if defined.

=cut
has 'sprintf' => (is => 'ro', isa => 'Maybe[Str]');



=head2 regex : RegexRef

Regex matching a file. The first capture parens are used to extract
the local file name.

If coerced from a string, define as qr$regex, i.e. specify the
delimiters and any needed flags.

=cut

subtype RegexRef
        => as RegexpRef
        => where { ref($_) eq "Regexp" };  #print "JPL: where: ($_) (" . ref($_) . ")\n";
coerce RegexRef
        => from 'Str'
        => via { regex_from_qr($_) };

has 'regex' => (
    is       => 'rw',
    isa      => 'RegexRef',
    coerce   => 1,
    required => 1,
);



=head1 METHODS

=head2 matching_file_fragment($file) : ($file_base, $file_fragment) | ()

Return two item list with (the base filename, the captured file name
fragment) from matching $file against regex, or () if nothing matched.

The $file_base is the $file, but with the whole matching regex
removed, forming the basis for looking up corresponding files.

=cut

sub matching_file_fragment {
    my $self = shift;
    my ($file) = @_;
    my $regex = $self->regex;

    my $file_base = $file;
    $file_base =~ s/$regex// and return ($file_base, $1);

    return ();
}



=head2 new_found_if_file_exists($matching_profile, $file_base, $fragment) : File::Found | ()

Return a new File::Corresponding::File::Found object if a file made up
of $file_base, this profile, and $fragment exists in the filesystem.

If not, return ().

=cut

sub new_found_if_file_exists {
    my $self = shift;
    my ($matching_profile, $file_base, $fragment) = @_;
    my $sprintf = $self->sprintf or return ();

    my $file = file($file_base, sprintf($sprintf, $fragment));

    -e $file or return ();

    return File::Corresponding::File::Found->new({
        # re-coerce into File object to make test happy
        file             => $file . "",
        matching_profile => $matching_profile,
        found_profile    => $self,
    });
}



=head1 SUBROUTINES

=head2 rex_from_qr($rex_string) : RegexRef

Convert $rex_string to a proper Regex ref, or die with a useful error
message.

=cut
sub regex_from_qr {
    my ($rex_string) = @_;
    my $rex = eval "qr $rex_string";
    $@ and die("Could not parse regexp ($rex_string):
$@
Correct regex syntax is e.g. '/ prove [.] bat /x'
");
    return $rex;
}



1;



__END__
