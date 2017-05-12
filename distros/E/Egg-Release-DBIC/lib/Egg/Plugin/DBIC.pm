package Egg::Plugin::DBIC;
use strict;
use warnings;
use Carp qw/ croak /;

our $VERSION = '0.03';

sub _setup {
	my($e)= @_;
	$e->is_model('dbic') || die q{ I want setup Egg::Model::DBIC. };
	my $project= $e->project_name;
	my $schemas= $e->global->{dbic_schemas};
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{"${project}::dbh"}= sub {
		my $self= shift;
		my $begins= $self->{dbic_begins} ||= $self->ixhash;
		if (my $s_name= lc(shift)) {
			$begins->{$s_name} || &{"${project}::begin_$s_name"}($self);
		} else {
			my @result;
			for my $label (keys %$schemas) {
				my $s_name= $label=~m{^dbic\:+(.+)} ? $1: $label;
				my $dbh= $begins->{$s_name}
				      || &{"${project}::begin_$s_name"}($self) || next;
				push @result, $dbh;
			}
			wantarray ? @result: \@result;
		}
	  };
	for my $accessor (qw/ commit rollback /) {
		*{"${project}::${accessor}_ok"}= sub {
			my $self= shift;
			my $label= lc(shift) || croak q{I want schema name.};
			my $s_name= $label=~m{^dbic\:+(.+)} ? $1: $label;
			my $ok= $self->{"dbic_${accessor}_ok"} ||= {};
			@_ ? $ok->{$s_name}= ($_[0] || 0) : ($ok->{$s_name} || 0);
		  };
	}
	*{"${project}::dbic_finalize_error"}= sub {
		my($self)= @_;
		my $begins= $self->{dbic_begins} || return 0;
		&{"${project}::rollback_$_"}($self) for keys %$begins;
		%$begins= ();
	  };
	*{"${project}::dbic_finish"}= sub {
		my($self)= @_;
		my $begins= $self->{dbic_begins} || return 0;
		my $commit= $self->{dbic_commit_ok}   || {};
		my $roback= $self->{dbic_rollback_ok} || {};
		for my $s_name (keys %$begins) {
			my $method= ($commit->{$s_name} and ! $roback->{$s_name})
			   ? "commit_$s_name": "rollback_$s_name";
			$self->$method;
		}
		%$begins= ();
	  };
	for my $label (keys %$schemas) {
		my $s_name= $label=~m{^dbic\:+(.+)} ? $1: $label;
		my $schema= $e->model($label);
		*{"${project}::schema_$s_name"}= sub {
			$_[0]->{"dbic_schema_$s_name"} ||= $_[0]->model($label);
		  };
		my $begin_code= $schema->storage->dbh->{AutoCommit} ? do {
			*{"${project}::commit_$s_name"}   = sub { 1 };
			*{"${project}::rollback_$s_name"} = sub { 1 };
			sub { 1 };
		  }: do {
			*{"${project}::commit_$s_name"}= sub {
				my($self)= @_;
				$self->dbh($label)->txn_commit;
				$self->debug_out("# + DBIC '$label' Transaction commit.");
				$self;
			  };
			*{"${project}::rollback_$s_name"}= sub {
				my($self)= @_;
				$self->dbh($label)->txn_rollback;
				$self->debug_out("# + DBIC '$label' Transaction rollback.");
				$self;
			  };
			sub {
				$_[1]->txn_begin;
				$_[0]->debug_out("# + DBIC '$label' Transaction Start.");
			  };
		  };
		*{"${project}::begin_$s_name"}= sub {
			my($self)= @_;
			my $begins= $self->{dbic_begins} ||= $self->ixhash;
			return $begins->{$s_name} if $begins->{$s_name};
			my $context= $self->model($label) || return 0;
			$begin_code->($self, $context);
			$begins->{$s_name}= $context->storage->dbh;
		  };
	}
	$e->next::method;
}
sub _finish {
	my $e= shift->next::method;
	$e->dbic_finish;
	$e;
}
sub _finalize_error {
	my($e)= @_;
	$e->dbic_finalize_error;
	$e->next::method;
}

1;

__END__

=head1 NAME

Egg::Plugin::DBIC - Plugin for Egg::Model::DBIC.

=head1 SYNOPSIS

  use Egg qw/ DBIC /;
  
  # $e->model('dbic::myschema');
  my $schema= $e->schema_myschema;
  
  # $e->model('dbic::myschema::hogetable');
  my $table= $e->schema_myschema->resultset('HogeTable');
  
  # The data base handler is acquired beginning the transaction.
  #  If AutoCommit is effective, the transaction is not done.
  my $dbh= $e->dbh('myschema');
    or
  my $dbh= $e->begin_myschema;
  
  # Committing and rollback.
  #  If AutoCommit is effective, nothing is done.
  $e->commit_myschema;
    or
  $e->rollback_myschema;
  
  # Delay committing or rollback.
  # It settles at the end of processing and the transaction is shut.
  $e->commit_ok( myschema => 1 );
    or
  $e->rollback_ok( myschema => 1 );

=head1 DESCRIPTION

It is a plugin that conveniently makes L<Egg::Model::DBIC> available only a 
little.

The controller is made the setup of L<Egg::Model::DBIC> to use it, and for this
 plugin to be read.

  use Egg qw/
    .............
    DBIC
    /;

This plugin adds a concerned some methods to Schema set up with
 L<Egg::Model::DBIC> to the project.

=head1 METHODS

=head2 dbh ([LABEL_NAME])

The data base handler is returned.

LABEL_NAME is a label name to call Schema. The part of first 'dbic::' of the 
label name is omissible.

  my $schema= $e->dbh('myschema');

When LABEL_NAME is omitted, all the data base handlers that L<Egg::Model::DBIC>
 reads are returned by the list.

  my @schema= $e->dbh;

If the transaction is effective, the transaction is begun at the same time.

=head2 begin_[schema_name]

The function is the same as 'dbh' method.

Because here uses the label name of Schema for the method name, it is not 
necessary to specify the argument.

  my $dbh= $e->begin_myschema;

=head2 commit_ok ([LABEL_NAME], [FLAG_BOOL]);

The delay committing is done when the transaction is effective.
This is used to settle at the end of processing and to commit it.

LABEL_NAME is a label name to call Schema. It is not omissible. 

FLAG_BOOL is a flag whether execute it. When 0 is redefined after it keeps 
effective, it becomes a cancellation.

  # The delay committing is effectively done.
  $e->commit_ok( myschema => 1 );
  
  # The delay committing is canceled.
  $e->commit_ok( myschema => 0 );

=head2 rollback_ok (LABEL_NAME], [FLAG_BOOL])

The delay rollback is done when the transaction is effective. This is used to
 settle at the end of processing and to do the rollback.

However, this plugin is effective, not effective the delay committing, either 
always does the rollback by the transaction, and completes processing.
Therefore, I think that it will use it by the cancellation usage when the 
delay committing is effectively done.

Even if the delay committing of same Schema effectively becomes it, it is 
disregarded when this method is made effective.

  # The delay rollback is made effective.
  $e->rollback_ok( myschema => 1 );
  
  # The delay rollback is invalidated.
  $e->rollback_ok( myschema => 0 );

=head2 schema_[schema_name]

The object of the schema is returned.

This is made to be able to write the place usually assumed the 
$e-E<gt>model('dbic::myschema') only a little short.

  my $schema= $e->schema_myschema;

=head2 commit_[schema_name]

If the transaction is effective, it immediately commits it.

  $e->commit_myschema;

=head2 rollback_[schema_name]

If the transaction is effective, the rollback is immediately done.

  $e->rollback_myschema;

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::DBIC>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

