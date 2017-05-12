package FBP::Project;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Object';
with    'FBP::Children';

has name => (
	is  => 'ro',
	isa => 'Str',
);

has relative_path => (
	is  => 'ro',
	isa => 'Bool',
);

has internationalize => (
	is  => 'ro',
	isa => 'Bool',
);

has encoding => (
	is  => 'ro',
	isa => 'Str',
);

has namespace => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;





######################################################################
# Convenience Methods

sub forms {
	return grep {
		Params::Util::_INSTANCE($_, 'FBP::Window')
		and
		$_->does('FBP::Form')
	} @{$_[0]->children};
}

sub dialogs {
	return grep { 
		Params::Util::_INSTANCE($_, 'FBP::Dialog')
	} @{$_[0]->children};
}

1;
