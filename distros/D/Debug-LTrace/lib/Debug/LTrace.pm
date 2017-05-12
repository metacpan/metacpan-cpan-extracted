package Debug::LTrace;

use warnings;
use strict;

use Devel::Symdump;
use Hook::LexWrap;
use Data::Dumper;
use Time::HiRes qw/gettimeofday tv_interval/;

=head1 NAME

Debug::LTrace - Perl extension to locally trace subroutine calls

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Debug::LTrace;

    {   
        
        my $tracer = Debug::LTrace->new('tsub'); # create local tracer
        tsub(1); # Tracing is on while $tracer is alive
        
    }   
    
    tsub(2); # Here tracing is off
    
    sub tsub {shift}

    #or  

    perl -MDebug::LTrace='*' yourprogram.pl # trace all subroutines in package main

=head1 DESCRIPTION

Debug::LTrace instruments subroutines to provide tracing information
upon every call and return. Using Debug::LTrace does not require any changes to your sources.
The trace information is output using the standard warn() function.

It was inspired by Debug::Trace, but introduces new features such as

=over

=item * 

Lexically scoped tracing

=item * 

Implements tracing in such way that the standard C<caller> function works correctly

=item * 

Enable package tracing (using '*' syntax)

=item * 

Nice output formatting

=item * 

More debug information (time of execution, call context...)

=back

Also Debug::LTrace supports Debug::Trace syntax (modifiers are not supported yet). 


Devel::TraceCalls - Powerful CPAN module but too complex API and not so convenient as Debug::LTrace



=head2 Some useful examples:

=over

=item from command line:

    # Trace "foo" and "bar" subroutines
    perl -MDebug::LTrace=foo,bar yourprogram.pl 

    # Trace all subroutines in current package ( "main" )
    perl -MDebug::LTrace='*' yourprogram.pl 
    
    # Trace all subroutines in package "SomeModule" and "AnotherModule::foo"
    perl -MDebug::LTrace='SomeModule::*, AnotherModule::foo' yourprogram.pl 


=item the same in code:

    # Trace "foo", "bar" subroutines in current package (can be not "main")
    use Debug::LTrace qw/foo bar/;  

    # Trace all subroutines in current package (can be not "main")
    use Debug::LTrace qw/*/; 
    
    # Trace all subroutines in package "SomeModule" and "AnotherModule::foo"
    use Debug::LTrace qw/SomeModule::* AnotherModule::foo/; 

=item local tracing (is on only when $tracer is alive):

    # Trace foo, bar subroutines in current package (can be not "main")
    my $tracer = Debug::LTrace->new( 'foo',  'bar' );  
    
    # Trace all subroutines in current package (can be not "main")
    my $tracer = Debug::LTrace->new('*'); 
    
    # Trace all subroutines in package SomeModule and AnotherModule::foo
    my $tracer = Debug::LTrace->new('SomeModule::*', 'AnotherModule::foo');
    
=back

=head2 Output trace log using custom function

Debug::LTrace outputs trace log using standart warn function. So you can catch SIGWARN with this code:

    $SIG{__WARN__} = sub {
        if ( $_[0] =~ /^TRACE/ ) {
            goto &custum_sub
        } else {
            print STDERR @_;  
        }
    }
    
=head1 METHODS

=head2 Debug::LTrace->new($sub [, $sub2, $sub3 ...] );

$sub can be fully-qualified subroutine name like C<SomePackage::foo> and will enable tracing for 
subroutine C<SomePackage::foo>

$sub can be short subroutine name like C<foo> willl enable tracing for subroutine C<foo> in current namespace 

$sub can be fully-qualified mask like C<SomePackage::*> will enable tracing for all subroutines in 
C<SomePackage> namespace including improrted ones  

=cut

my %import_params;
my @permanent_objects;

sub import {
    shift;
    $import_params{ ${ \scalar caller } } = [@_];
}

INIT {
    while ( my ( $package, $params ) = each %import_params ) {
        push @permanent_objects, __PACKAGE__->_new( $package, @$params ) if @$params;
    }
}

# External constructor
sub new {
    return unless defined wantarray;
    my $self = shift->_new( scalar caller, @_ );
    $self;
}

# Internal constructor
sub _new {
    my ( $class, $trace_package, @params ) = @_;
    my $self;

    # Parse input parameters
    foreach my $p (@params) {
        next if $p =~ /^:\w+/;    # TODO parse modifier and set config

        #process sub
        $p = $trace_package . '::' . $p unless $p =~ m/::/;
        push @{ $self->{subs} }, (
            $p =~ /^(.+)::\*(\*?)$/
            ? Devel::Symdump ->${ \( $2 ? 'rnew' : 'new' ) }($1)->functions()
            : $p
            );
    }

    bless $self, $class;

    $self->_start_trace();
    $self;
}

# Bind all hooks for tracing
sub _start_trace {
    my ($self) = @_;
    return unless ref $self;

    $self->{wrappers} = {};
    my @messages;

    foreach my $sub ( @{ $self->{subs} } ) {
        next if $self->{wrappers}{$sub};    # Skip already wrapped

        $self->{wrappers}{$sub} = Hook::LexWrap::wrap(
            $sub,
            pre => sub {
                pop();
                my ( $pkg, $file, $line ) = caller(0);
                my ($caller_sub) = ( caller(1) )[3];

                my $args = __PACKAGE__->_dump( \@_ );

                my $msg = "/-$sub($args) called at $file line $line "
                    . ( defined $caller_sub ? "sub $caller_sub" : "package $pkg" );

                warn "TRACE C: " . "| " x @messages . "$msg\n";
                unshift @messages, [ "$sub($args)", [ gettimeofday() ] ];
            },
            post => sub {
                my $wantarray = ( caller(0) )[5];
                my $call_data = shift(@messages);

                my $msg = $call_data->[0]
                    . (
                    defined $wantarray
                    ? ' returned: (' . __PACKAGE__->_dump( $wantarray ? pop : [pop] ) . ')'
                    : ' [VOID]'
                    )
                    . ' in '
                    . tv_interval( $call_data->[1], [gettimeofday] ) . ' sec';
                warn "TRACE R: " . "| " x @messages . "\\_$msg\n";
            } );
    }
    $self;
}

# Make a nice dump of structure
sub _dump {
    my ( $class, $ref ) = @_;
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Maxdepth = 3;
    my $string = Data::Dumper->Dump( [$ref] );
    $string = $1 if $string =~ /\[(.*)\];/s;
    $string;
}

=head1 TODO

=over

=item * 

improve Debug::LTrace compatibility (add modifiers support)

=item * 

enabling tracing for whole tree of modules

=item * 

callback support to handle debug output

=back


=head1 AUTHOR

"koorchik", C<< <"koorchik at cpan.org"> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-debug-ltrace at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Debug-LTrace>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Debug::LTrace


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Debug-LTrace>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Debug-LTrace>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Debug-LTrace>

=item * Search CPAN

L<http://search.cpan.org/dist/Debug-LTrace/>

=back



=head1 LICENSE AND COPYRIGHT

Copyright 2010 "koorchik".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Debug::Trace>, L<Devel::TraceCalls>,  L<Hook::LexWrap>, L<Devel::Symdump>

=cut

1;    # End of Debug::LTrace
