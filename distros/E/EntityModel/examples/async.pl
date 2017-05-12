#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

# Warning: This is an incomplete example. Please see the documentation or t/*.t files instead.

use EntityModel;

=pod

If the first parameter is a hashref, additional options may be given:

 Entity::Thing->create({
 	},
	done	=> sub { ... },
	fail	=> sub { ... },
 );

=cut


=pod

# Bring the model in at compilation stage, since I have a vague
# idea that perhaps this way performance is better.
BEGIN {
	my $model = EntityModel->new;
}

=cut

package Mixin::Deferrable;
sub fail {
	my ($self, $code) = @_;
	if($self->{failed}) {
		$code->($self);
		return $self;
	}

	$self->{on_fail} = $code;
	return $self;
}

sub done {
	my ($self, $code) = @_;
	if($self->{finished}) {
		$code->($self);
		return $self;
	}

	$self->{on_done} = $code;
	return $self;
}

package Entity::Country;
use parent -norequire => 'Mixin::Deferrable';

sub create {
	my $class = shift;

	my $self = bless {
		id => 14
	}, $class;
	$self->{finished} = 1;
	return $self;
}

sub id { shift->{id} }
sub name { shift->{name} }

package Entity::Address;
use parent -norequire => 'Mixin::Deferrable';

sub create {
	my $class = shift;

	my $self = bless {
		id => 9
	}, $class;
	$self->{finished} = 1;
	return $self;
}

sub id { shift->{id} }
sub name { shift->{name} }

package Entity::Author;
use parent -norequire => 'Mixin::Deferrable';

sub create {
	my $class = shift;

	my $self = bless {
		id => 9
	}, $class;
	$self->{finished} = 1;
	return $self;
}

sub id { shift->{id} }
sub name { shift->{name} }

package Entity::Book;
use parent -norequire => 'Mixin::Deferrable';

sub create {
	my $class = shift;
	my @args = @_;

	my $self = bless {
		id => 3,

	}, $class;
	$self->{finished} = 1;
	return $self;
}

sub id { shift->{id} }
sub title { shift->{title} }

#package Deferrable::Util;
#use parent qw(Exporter);
#our @EXPORT_OK = qw(prepare);

package main;
use Scalar::Util qw(blessed);
#use Deferrable::Util qw(prepare);

=head2 prepare

=cut

sub prepare {
	my $req = shift;
	my %args = @_;

# Any entries that are still pending
	my %pending;
# Completed data items
	my %data;
# Failed entries
	my %failed;

# Hit the appropriate callback on completion
	my $done = 0;
	my $complete = sub {
		return if $done++;

		if(keys %failed) {
			return $args{fail}->(\%data, \%failed) if $args{fail};
			die "Failed keys: " . (join ',', keys %failed) . "\n";
		}

		return $args{done}->(\%data);
	};

# Any entries that inherit from the Deferrable mixin need to be queued,
# we do this first so that we know exactly how many we're waiting for
	%pending = map {
		$_ => $req->{$_}
	} grep {
		blessed($req->{$_}) && $req->{$_}->isa('Mixin::Deferrable')
	} keys %$req;

# Queue events and copy values
	foreach my $k (keys %$req) {
		if(exists $pending{$k}) {
			$req->{$k}->done(sub {
				$data{$k} = shift;
				delete $pending{$k};
				$complete->() unless keys %pending;
			})->fail(sub {
				$failed{$k} = shift;
				delete $pending{$k};
				$complete->() unless keys %pending;
			});
# Everything else can be used as-is
		} else {
			$data{$k} = $req->{$k};
		}
	}

# Hit the completion point if everything is already in place
	$complete->() unless keys %pending;
}

# Use ->lookup to find a single entry, ->create to create a single entry,
# and ->lookup_or_create to use the existing entry if available and create
# a new one if not.

Entity::Country->create(
	name => 'UK'
);

# Default behaviour is to ->lookup_or_create
Entity::Book->create(
	title	=> 'Some book title',
	author	=> {
		name	=> 'Fred',
		address	=> {
			street => 'Some road',
			country => {
				-action	=> 'lookup',
				name	=> 'UK',
			}
		}
	}
)->done(sub {
	my $book = shift;
	printf "We now have a book with ID [%s], title %s, author %s (id %s), address id %s with street %s, country %s (id %s)\n",
		$book->id,
		$book->title,
		$book->author->name,
		$book->author->id,
		$book->author->address->id,
		$book->author->address->street,
		$book->author->address->country->name,
		$book->author->address->country->id;
})->fail(sub {
	warn "Something went wrong\n";
});


# Nested creation will wait until all components are ready before hitting the callback,
# and the resulting structure will be fully populated
prepare {
	book	=> Entity::Book->create(
		title	=> 'Some book title',
		author	=> Entity::Author->lookup_or_create(
			name	=> 'Fred',
			address	=> Entity::Address->lookup_or_create(
				street => 'Some road',
				country => Entity::Country->lookup(
					name => 'UK'
				)
			)
		)
	)
}, done => sub {
	my $data = shift;
	say "Book was created with ID " . $data->{book}->id . " and author " . $data->{book}->author->id;
}, fail => sub {
	say "Failed: @_\n";
};

