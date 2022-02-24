package Lemonldap::NG::Portal::Plugins::AutoSignin;

use strict;
use Mouse;
use Safe;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
);

our $VERSION = '2.0.8';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# INTERFACE

use constant beforeAuth => 'check';

# INITIALIZATION

has rules => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] }
);

sub init {
    my ($self) = @_;
    if ( my $rules = $self->conf->{autoSigninRules} ) {
        my $safe = Safe->new;
        foreach my $id ( sort keys %$rules ) {
            my $sub =
              $safe->reval( 'sub{my($env)=@_;return (' . $rules->{$id} . ')}' );
            if ($@) {
                $self->logger->error(
                    'Bad Autologin rule "' . $rules->{$id} . ": $@" );
                $self->logger->debug(
                    "Skipping Autologin rule for user \"$id\"");
                next;
            }
            $self->logger->debug("Autologin rule for user \"$id\" appended");
            $id =~ s/^\s*([\w\-\@]+)\s*/$1/;
            push @{ $self->rules }, [ $sub, $id ];
        }
    }

    return 1;
}

# RUNNING METHODS

sub check {
    my ( $self, $req ) = @_;

    foreach ( @{ $self->rules } ) {
        my ( $test, $name ) = @$_;
        $self->logger->debug("Autosignin: testing user $name");
        if ( $test->( $req->env ) ) {
            $req->user($name);
            my @steps =
              grep {
                !ref $_
                  and $_ !~ /^(?:extractFormInfo|authenticate|secondFactor)$/
              } @{ $req->steps };
            $req->steps( \@steps );
            $self->userLogger->notice("Autosignin for $name");
            return PE_OK;
        }
    }
    return PE_OK;
}

1;
