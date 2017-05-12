package Lingua::TH::Segmentation;

use 5.00503;
use strict;

require Exporter;
require DynaLoader;
use vars qw($VERSION @ISA @EXPORT_OK);
@ISA = qw(Exporter
	DynaLoader);

@EXPORT_OK = qw();

$VERSION = '0.08';

bootstrap Lingua::TH::Segmentation $VERSION;

sub new {
	my $class=shift;
	my $self={};
	$self->{wc}=Lingua::TH::Segmentation->get_wc();
	bless $self,$class;
}

sub separate {
	my $self=shift;
	$self->string_separate($self->{wc},$_[0],$_[1]);
}

sub cut_raw {
	my $self=shift;
	my $tmp=$self->wordcut($self->{wc},$_[0]);
	split(/#K_=/,$tmp);
}

sub cut_no_space {
	my $self=shift;
	my $tmp=$self->wordcut($self->{wc},$_[0]);
	my @result;
	foreach (split(/#K_=|\s+/,$tmp)) {
		push @result,$_ if defined $_;
	}

	@result;
}

sub cut {
	my $self=shift;
	my $tmp=$self->wordcut($self->{wc},$_[0]);
	my @result;
	foreach (split(/#K_=|(\s+)/,$tmp)) {
		push @result,$_ if defined $_;
	}

	@result;
}

sub DESTROY {
	my $self=shift;
	#print "exists:".exists($self->{wc});
	#print $self->wordcut($self->{wc},'äÍéºéÒ');
	#$self->destroy_wc($self->{wc});
}

1;
__END__

=head1 NAME

Lingua::TH::Segmentation - an object-oriented interface of TH word segmentation

=head1 SYNOPSIS

	use Lingua::TH::Segmentation;

	#create object
	$sg=Lingua::TH::Segmentation->new();

	# insert separator to $thai_string
	$result=$sg->separate($thai_string,$separator);

	# split $thai_string to array include all spacing
	@result=$sg->cut($thai_string);

	# split $thai_string to array exclude spacing
	@result=$sg->cut_no_space($thai_string);

	# split $thai_string to array as of the original library
	@result=$sg->cut_raw($thai_string);

=head1 DESCRIPTION

TH language is known to be a "word-sticked language", all words in a sentence are next to each other with out spacing. It is hard for programmers to solve problems, such as translating or searching, on this kind of language.

The module is a object-oriented interface of TH word segmentation library (http://thaiwordseg.sourceforge.net).

=head2 EXPORT

None by default.

=head1 SEE ALSO

http://thaiwordseg.sourceforge.net

=head1 AUTHOR

Komtanoo  Pinpimai(romerun@romerun.com)

=head1 COPYRIGHT AND LICENSE

Perl License.

=cut
