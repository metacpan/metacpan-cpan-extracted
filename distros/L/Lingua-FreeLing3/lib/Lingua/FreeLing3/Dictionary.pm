package Lingua::FreeLing3::Dictionary;

use 5.010;

use warnings;
use strict;

use Carp;
use Lingua::FreeLing3;
use Lingua::FreeLing3::Config;
use File::Spec::Functions 'catfile';
use Lingua::FreeLing3::Bindings;
use Lingua::FreeLing3::Sentence;

use parent -norequire, 'Lingua::FreeLing3::Bindings::dictionary';

our $VERSION = "0.01";

=encoding UTF-8

=head1 NAME

Lingua::FreeLing3::Dictionary - Interface to FreeLing3 Dictionary

=head1 SYNOPSIS

   use Lingua::FreeLing3::Dictionary;

=head1 DESCRIPTION

Interface to the FreeLing3 Dictionary files.

=head2 C<new>

Object constructor. One argument is required: the languge code
(C<Lingua::FreeLing3> will search for the dictionary data file). In
this case, default options will be used.

To supply further options, use:

  my $dic = Lingua::FreeLing3::Dictionary->new(
                  lang => 'ES',
                  analyzeAffixation => 1, # defaults to 0
                  inverseAccess => 1,     # defaults to 0
                  retokContractions => 1, # defaults to 0
            );

Returns the dictionary object for that language, or undef in case of
failure.

=cut

sub new {
    my $class = shift;
    my ($config, $lang, %opts);
    my ($affix, $affixFile) = (0, "");
    my ($inverse, $retok) = (0, 0);

    if (@_ && @_ == 1) {
        $lang = shift;
        $config = Lingua::FreeLing3::Config->new($lang);
    }
    elsif (@_ && scalar(@_)%2==0) {
        %opts = @_;
        $lang  = $opts{lang} || die "'lang' option is required for Dictionay constructor.";
        $config = Lingua::FreeLing3::Config->new($lang);

        if (exists($opts{analyzeAffixation}) && $opts{analyzeAffixation}) {
            $affix = 1;
            $affixFile = $config->config('AffixFile');
        }
        $inverse = 1 if exists($opts{inverseAccess})     && $opts{inverseAccess};
        $retok   = 1 if exists($opts{retokContractions}) && $opts{retokContractions};
    }
    else {
        die "No idea how to hangle options passed to Dictionary constructor."
    }

    my $file = $config->config('DictionaryFile');

    unless (-f $file) {
        carp "Cannot find dictionary data file. Tried [$file]\n";
        return undef;
    }

    my $self = $class->SUPER::new($lang, $file, $affix, $affixFile, $inverse, $retok);
    return bless $self => $class
}

=head2 C<get_forms>

Returns a list of possible derivative forms from a specific word, and
a Part-Of-Speech tag.

 $forms = $dict->get_forms('carro', 'NCMP000');

=cut

sub get_forms {
    my ($self, $word, $tag) = @_;

    my $result = $self->SUPER::get_forms($word, $tag);

    return $result;
}

1;

__END__

=head1 SEE ALSO

Lingua::FreeLing3(3) for the documentation table of contents. The
freeling library for extra information, or perl(1) itself.

=head1 AUTHOR

Alberto Manuel Brandão Simões, E<lt>ambs@cpan.orgE<gt>

Jorge Cunha Mendes E<lt>jorgecunhamendes@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Projecto Natura

=cut
