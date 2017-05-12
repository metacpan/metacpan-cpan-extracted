package Lingua::FreeLing3::NEC;
# albie@alfarrabio.di.uminho.pt          01 Feb 2012

use 5.006;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use File::Spec::Functions;
use Lingua::FreeLing3;
use Lingua::FreeLing3::Bindings;
use Lingua::FreeLing3::Config;
use parent -norequire, 'Lingua::FreeLing3::Bindings::nec';

our $VERSION = "0.01";

=encoding UTF-8

=head1 NAME

Lingua::FreeLing3::NEC - Interface to FreeLing3 NEC object

=head1 SYNOPSIS

   use Lingua::FreeLing3::NEC;

=head1 DESCRIPTION

This module is a wrapper to the FreeLing3 NEC object.

=head2 CONSTRUCTOR

=over 4

=item C<new>

The constructor returns a new NEC object.

=back

=cut


sub new {
    my ($class, $lang) = @_;

    my $config = Lingua::FreeLing3::Config->new($lang);
    my $file = $config->config("NECFile");

    unless (-f $file) {
        carp "Cannot find NEC data file. Tried [$file]\n";
        return undef;
    }

    my $self = $class->SUPER::new($file);
    return bless $self => $class
}


=head2 C<analyze>

Receives a list of sentences, and returns that same list of sentences
with classified entities.

=cut

sub analyze {
    my ($self, $sentences, %opts) = @_;

    unless (Lingua::FreeLing3::_is_sentence_list($sentences)) {
        carp "Error: analyze argument isn't a list of sentences";
        return undef;
    }

    $sentences = $self->SUPER::analyze($sentences);

    for my $s (@$sentences) {
        $s = Lingua::FreeLing3::Sentence->_new_from_binding($s);
    }
    return $sentences;
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

Copyright (C) 2011-2012 by Projecto Natura

=cut


