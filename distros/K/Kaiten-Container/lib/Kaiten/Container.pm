package Kaiten::Container;

use v5.10;
use strict;
use warnings FATAL => 'recursion';

=head1 NAME

Kaiten::Container - Simples dependency-injection (DI) container, distant relation of IoC.

=head1 VERSION

Version 0.37

=cut

our $VERSION = '0.37';

use Moo;

use Carp qw(croak carp);
use Scalar::Util qw(reftype);

#======== DEVELOP THINGS ===========>
# develop mode
#use Smart::Comments;
#use Data::Printer;
#======== DEVELOP THINGS ===========<

my $error = [
              'Error: handler [%s] not defined at [init], die ',
              'Error: handler [%s] init wrong, [probe] sub not defined, die ',
              'Warning: handler [%s] don`t pass [probe] check on reuse with message [ %s ], try to create new one, working ',
              'Error: handler [%s] don`t pass [probe] check on create, with message [ %s ], die  ',
              'Error: [init] value must be HASHREF only, die ',
              'Error: [add] method REQUIRE handlers at args, die',
              'Error: handler [%s] exists, to rewrite handler remove it at first, die ',
              'Error: [remove] method REQUIRE handlers at args, die',
              'Error: handler [%s] NOT exists, nothing to remove, die ',
            ];

has 'init' => (
    is       => 'rw',
    required => 1,
    isa      => sub {
        croak sprintf $error->[4] unless ( defined $_[0] && ( reftype $_[0] || '' ) eq 'HASH' );
    },
    default => sub { {} },
              );

has 'DEBUG' => (
    is       => 'rw',
    default => sub { 0 },
);

has 'CANCEL_REUSE' => (
    is       => 'rw',
    default => sub { 0 },
);

has '_cache' => (
                  is      => 'rw',
                  default => sub { {} },
                );

=head1 SYNOPSIS

This module resolve dependency injection conception in easiest way ever.
You are just create some code first and put it on kaiten in named container.
Later you take it by name and got yours code result fresh and crispy.

No more humongous multi-level dependency configuration, service provider and etc.

You got what you put on, no more, no less.

Ok, a little bit more - L<Kaiten::Container> run I<probe> sub every time when you want to take something to ensure all working properly.

And another one - KC try to re-use I<handler> return if it requested.

Ah, last but not least - KC MAY resolve deep dependencies, if you need it. Really. A piece of cake!

    use Kaiten::Container;

    my $config = {
         ExampleP => {
             handler  => sub {
                return DBI->connect( "dbi:ExampleP:", "", "", { RaiseError => 1 } ) or die $DBI::errstr;
              },
             probe    => sub { shift->ping() },
             settings => { reusable => 1 }
         },
    };

    my $container = Kaiten::Container->new( init => $config, DEBUG => 1 );
    my $dbh = $container->get_by_name('ExampleP');

All done, now we are have container and may get DB handler on call.
Simple!

=head1 SETTINGS

=head2 C<DEBUG>

This settings to show some debug information. To turn on set it to 1, by default disabled.

=head2 C<CANCEL_REUSE>

This settings suppress C<reusable> properties for all handlers in container. To turn on set it to 1, by default disabled.

May be helpfully in test mode, when you need replace some method with mock, but suppose its already may be cached in descendant handlers. 

=head1 SUBROUTINES/METHODS

=head2 C<new(%init_configuration?)>

This method create container with entities as I<init> configuration hash values, also may called without config.
Its possible add all entities later, with C<add> method.

    my $config = {
         examplep_config => {
            handler  => sub { { RaiseError => 1 } },
            probe    => sub { 1 },
            settings => { reusable => 1 },
         },
         examplep_dbd => {
            handler  => sub { "dbi:ExampleP:" },
            probe    => sub { 1 },
            settings => { reusable => 1 },      
         },
         # yap! this is deep dependency example.
         ExampleP => {
             handler  => sub { 
                my $c = shift;
                
                my $dbd = $c->get_by_name('examplep_dbd');
                my $conf = $c->get_by_name('examplep_config');
                
                return DBI->connect( $dbd, "", "", $conf ) or die $DBI::errstr;
              },
             probe    => sub { shift->ping() },
             settings => { reusable => 1 }
         },
         test => {
             handler  => sub        { return 'Hello world!' },
             probe    => sub        { return 1 },
        },
    };

    my $container = Kaiten::Container->new( init => $config );  

Entity have next stucture:

=over

=item * unique name (REQUIRED)

This name used at C<get_by_name> method.

=over

=item - C<handler> (REQUIRED)

This sub will be executed on C<get_by_name> method, at first argument its got I<container> itself.

=item - C<probe> (REQUIRED)

This sub must return true, as first arguments this sub got I<handler> sub result.

=item - C<settings> (OPTIONAL)

- C<reusable> (OPTIONAL)

If it setted to true - KC try to use cache. If cached handler DONT pass I<probe> KC try to create new one instance.

=back

=back

NB. New instance always be tested by call I<probe>. 
If you dont want test handler - just cheat with 

    probe => sub { 1 }

but its sharp things, handle with care.

=head3 Something about deep dependencies

Its here, its worked.

    handler  => sub {
      # any handler sub get container as first arg
      my $container = shift;
      
      my $dbd = $container->get_by_name('examplep_dbd');
      my $conf = $container->get_by_name('examplep_config');
      
      return DBI->connect( $dbd, "", "", $conf ) or die $DBI::errstr;
    },

Warning! Its been worked predictably only at ONE container scope.
Mixing deep dependencies from different containers seems... hm, you know, very strange.
And dangerous.

What about circular dependencies? Its cause 'die'. Don`t do that.

=head2 C<get_by_name($what)>

Use this method to execute I<handler> sub and get it as result.

    my $dbh = $container->get_by_name('ExampleP');
    # now $dbh contain normal handler to ExampleP DB

=cut

sub get_by_name {
    my $self         = shift;
    my $handler_name = shift;

    my $handler_config = $self->init->{$handler_name};

    croak sprintf( $error->[0], $handler_name ) unless defined $handler_config;
    croak sprintf( $error->[1], $handler_name ) unless defined $handler_config->{probe} && ( reftype $handler_config->{probe} || '' ) eq 'CODE';

    my $result;

    my $reusable = defined $handler_config->{settings} && $handler_config->{settings}{reusable};

    if ( !$self->CANCEL_REUSE && $reusable && defined $self->_cache->{$handler_name} ) {
        $result = $self->_cache->{$handler_name};

        # checkout handler and wipe it if it don`t pass [probe]
        unless ( eval { $handler_config->{probe}->($result) } ) {
            carp sprintf( $error->[2], $handler_name, $@ ) if $self->DEBUG;
            $result = undef;
        }
    }

    unless ($result) {
        $result = $self->init->{$handler_name}{handler}->($self);

        # checkout handler and die it if dont pass [probe]
        unless ( eval { $handler_config->{probe}->($result) } ) {
            croak sprintf( $error->[3], $handler_name, $@ );
        }
    }

    # put it to cache if it used
    $self->_cache->{$handler_name} = $result if ( !$self->CANCEL_REUSE && $reusable );

    return $result;
}

=pod

=head2 C<add(%config)>

Use this method to add some more entities to container.

    my $configutarion_explodable = {
           explode => {
                        handler  => sub        { return 'ExplodeSQL there!' },
                        probe    => sub        { state $a= [ 1, 0, 0 ]; return shift @$a; },
                        settings => { reusable => 1 }
                      },
           explode_now => { 
                        handler => sub { return 'ExplodeNowSQL there!' },
                        probe    => sub        { 0 },
                        settings => { reusable => 1 }
                      },
    };

    $container->add(%$configutarion_explodable); # list, NOT hashref!!!
    
=cut

sub add {
    my $self     = shift;
    my %handlers = @_;

    croak sprintf $error->[5] unless scalar keys %handlers;

    while ( my ( $handler_name, $handler_config ) = each %handlers ) {

        croak sprintf( $error->[6], $handler_name ) if exists $self->init->{$handler_name};

        $self->init->{$handler_name} = $handler_config;

    }

    return $self;
}

=pod

=head2 C<remove(@what)>

This method remove some entities from container

    $container->remove('explode_now','ExampleP'); # list, NOT arayref!!!

=cut

sub remove {
    my $self     = shift;
    my @handlers = @_;

    croak sprintf $error->[7] unless scalar @handlers;

    foreach my $handler_name (@handlers) {

        croak sprintf( $error->[8], $handler_name ) if !exists $self->init->{$handler_name};

        delete $self->init->{$handler_name};

        # clear cache if it exists too
        delete $self->_cache->{$handler_name} if exists $self->_cache->{$handler_name};

    }

    return $self;
}

=pod

=head2 C<show_list>

Use this method to view list of available handler in container

    my @handler_list = $container->show_list;
    
    # @handler_list == ( 'examplep_config', 'examplep_dbd', 'explode', 'test' )

NB. Entities sorted with perl C<sort> function

=cut

sub show_list {
    my $self = shift;

    my @result = sort keys %{ $self->init };
    return wantarray ? @result : \@result;

}

=pod

=head2 C<test(@what?)>

Use this method to test handlers works correctly.
If no handlers name given - will be tested ALL.

    my $test_result = $container->test();

Method return 1 if it seems all ok, or die.

I<Very helpfully for TEST suite, especially if deep dependency used.
Using this method at production are may helpfully too, but may couse overhead.>

=cut

sub test {
    my $self     = shift;
    my @handlers = @_;

    @handlers = $self->show_list unless scalar @handlers;

    $self->get_by_name($_) foreach @handlers;

    return 1;
}

=head1 AUTHOR

Meettya, C<< <meettya at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-kaiten-container at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Kaiten-Container>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 DEVELOPMENT

=head2 Repository

    https://github.com/Meettya/Kaiten-Container


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Kaiten::Container


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Kaiten-Container>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Kaiten-Container>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Kaiten-Container>

=item * Search CPAN

L<http://search.cpan.org/dist/Kaiten-Container/>

=back

=head1 SEE ALSO

L<Bread::Board> - a Moose-based DI framework

L<IOC> - the ancestor of L<Bread::Board>

L<Peco::Container> - another DI container

L<IOC::Slinky::Container> - an alternative DI container

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Meettya.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Kaiten::Container
