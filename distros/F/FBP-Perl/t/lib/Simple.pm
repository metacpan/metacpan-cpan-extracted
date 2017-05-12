package t::lib::Simple;

## no critic

use 5.008005;
use utf8;
use strict;
use warnings;
use Wx 0.98 ':everything';
use Wx::Html ();
use Wx::Locale ();

our $VERSION = '0.78';
our @ISA     = 'Wx::App';

sub run {
	my $class = shift;
	my $self  = $class->new(@_);
	return $self->MainLoop;
}

sub OnInit {
	my $self = shift;

	# Create the primary frame
	require t::lib::MyFrame1;
	$self->SetTopWindow( t::lib::MyFrame1->new );

	# Don't flash frames on the screen in tests
	unless ( $ENV{HARNESS_ACTIVE} ) {
		$self->GetTopWindow->Show(1);
	}

	return 1;
}

1;
