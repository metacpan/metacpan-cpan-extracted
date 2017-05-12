#   $Header: /cvsroot/pmilter/Mail-Milter/t/02_object.t,v 1.1 2004/02/26 11:26:53 rob_au Exp $

#   Copyright (c) 2002-2004 Todd Vierling <tv@duh.org> <tv@pobox.com>
#   Copyright (c) 2004 Robert Casey <rob.casey@bluebottle.com>
#
#   This file is covered by the terms in the file COPYRIGHT supplied with this
#   software distribution.

BEGIN {

    use Test::More 'tests' => 40;

    use_ok('Mail::Milter::Object');
    use_ok('Sendmail::Milter');
}


#   Perform some basic tests of the module constructor and available methods - 
#   Whilst the underlying package object is not normally examined directly, 
#   this is performed in the testing of Mail::Milter::Object as a result of 
#   it's intended used as the callbacks argument to the Sendmail::Milter 
#   register method.

can_ok(
        'Mail::Milter::Object',
                'new'
);


ok( my $callback = TestMMO->new );
isa_ok( $callback, 'Mail::Milter::Object' );
isa_ok( $callback, 'HASH' );


my @callbacks = keys %Sendmail::Milter::DEFAULT_CALLBACKS;
foreach my $name (@callbacks) {

    my $method = sprintf('%s_callback', $name);
    SKIP: {

        skip(3, "- No such package method $method") unless UNIVERSAL::can( $callback, $method );


        #   Unfortunately, one test which cannot be performed is a direct comparison of 
        #   the code references - This is due to the creation of an anonymous 
        #   subroutine to call the underlying code reference within the 
        #   Mail::Milter::Object constructor.
        #
        #   In place of this comparison of code references, return values from these
        #   code references are used for comparison.


        ok( exists $callback->{$name}, $method );

        my $subroutine = $callback->{$name};
        isa_ok( $subroutine, 'CODE' );
        is( &$subroutine, $callback->$method() );
    }
}


#   Test that the additional package methods test1_callback and test2_callback 
#   have been defined within the package namespace and ensure that these have 
#   not been incorporated into the package object.

ok( UNIVERSAL::can( $callback, 'test1_callback' ) );
ok( ! exists $callback->{'test1_callback'} );
ok( UNIVERSAL::can( $callback, 'test2_callback' ) );
ok( ! exists $callback->{'test2_callback'} );


package TestMMO;


use base Mail::Milter::Object;


sub connect_callback    ()  { 1 }
sub helo_callback       ()  { 2 }
sub envfrom_callback    ()  { 3 }
sub envrcpt_callback    ()  { 4 }
sub header_callback     ()  { 5 }
sub eoh_callback        ()  { 6 }
sub body_callback       ()  { 7 }
sub eom_callback        ()  { 8 }
sub close_callback      ()  { 9 }
sub abort_callback      ()  { 10 }

sub test1_callback      ()  {}
sub test2_callback      ()  {}


1;


__END__
