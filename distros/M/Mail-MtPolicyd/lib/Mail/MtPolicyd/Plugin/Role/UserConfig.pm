package Mail::MtPolicyd::Plugin::Role::UserConfig;

use strict; # make critic happy
use MooseX::Role::Parameterized;

our $VERSION = '2.03'; # VERSION
# ABSTRACT: role for plugins using per user/request configuration

parameter uc_attributes => (
        isa      => 'ArrayRef',
        required => 1,
);

role {
	my $p = shift;

	foreach my $attribute ( @{$p->uc_attributes} ) {
		has 'uc_'.$attribute => ( 
			is => 'rw',
			isa => 'Maybe[Str]',
		);
	}
};

sub get_uc {
	my ($self, $session, $attr) = @_;
	my $uc_attr = 'uc_'.$attr;
	
	if( ! $self->can($uc_attr) ) {
		die('there is no user config attribute '.$uc_attr.'!');
	}
	if( ! defined $self->$uc_attr ) {
		return $self->$attr;
	}
	my $session_value = $session->{$self->$uc_attr};
	if( ! defined $session_value ) {
		return $self->$attr;
	}
	return $session_value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Plugin::Role::UserConfig - role for plugins using per user/request configuration

=head1 VERSION

version 2.03

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
