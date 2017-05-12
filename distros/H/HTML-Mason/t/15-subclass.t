use strict;
use warnings;

use HTML::Mason::Tests;

{
    package HTML::Mason::Request::Test;

    @HTML::Mason::Request::Test::ISA = 'HTML::Mason::Request';

    __PACKAGE__->valid_params( foo_val => { parse => 'string', type => Params::Validate::SCALAR } );

    # shuts up 5.00503 warnings
    1 if $HTML::Mason::ApacheHandler::VERSION;
    1 if $HTML::Mason::CGIHandler::VERSION;

    sub new
    {
        my $class = shift;

        $class->alter_superclass( $HTML::Mason::ApacheHandler::VERSION ?
                                  'HTML::Mason::Request::ApacheHandler' :
                                  $HTML::Mason::CGIHandler::VERSION ?
                                  'HTML::Mason::Request::CGI' :
                                  'HTML::Mason::Request' );

        my $self = $class->SUPER::new(@_);
    }

    sub foo_val { $_[0]->{foo_val} }
}

{
    package HTML::Mason::Request::Test::Subclass;

    @HTML::Mason::Request::Test::Subclass::ISA = 'HTML::Mason::Request::Test';

    __PACKAGE__->valid_params( bar_val => { parse => 'string', type => Params::Validate::SCALAR } );

    sub bar_val { $_[0]->{bar_val} }
}

{
    package HTML::Mason::Lexer::Test;

    @HTML::Mason::Lexer::Test::ISA = 'HTML::Mason::Lexer';

    __PACKAGE__->valid_params( bar_val => { parse => 'string', type => Params::Validate::SCALAR } );

    sub bar_val { $_[0]->{bar_val} }
}

{
    package HTML::Mason::Compiler::ToObject::Test;

    @HTML::Mason::Compiler::ToObject::Test::ISA = 'HTML::Mason::Compiler::ToObject';

    __PACKAGE__->valid_params( baz_val => { parse => 'string', type => Params::Validate::SCALAR } );

    sub baz_val { $_[0]->{baz_val} }

    sub compiled_component
    {
        my $self = shift;

        my $comp = $self->SUPER::compiled_component(@_);

        $$comp =~ s/!!BAZ!!/$self->{baz_val}/g;

        return $comp;
    }
}

my $tests = make_tests();
$tests->run;

sub make_tests
{
    my $group = HTML::Mason::Tests->tests_class->new( name => 'subclass',
                                                      description => 'Test use of subclasses for various core classes' );

#------------------------------------------------------------

    $group->add_test( name => 'request_subclass',
                      description => 'use a HTML::Mason::Request subclass',
                      interp_params => { request_class => 'HTML::Mason::Request::Test',
                                         foo_val => 77 },
                      component => <<'EOF',
% if ( $m->can('foo_val') ) {
foo_val is <% $m->foo_val %>
% } else {
this request cannot ->foo_val!
% }
EOF
                      expect => <<'EOF',
foo_val is 77
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'request_subclass_of_subclass',
                      description => 'use a HTML::Mason::Request grandchild',
                      interp_params =>
                      { request_class => 'HTML::Mason::Request::Test::Subclass',
                        foo_val => 77,
                        bar_val => 42,
                      },
                      component => <<'EOF',
% if ( $m->can('foo_val') ) {
foo_val is <% $m->foo_val %>
% } else {
this request cannot ->foo_val!
% }
% if ( $m->can('bar_val') ) {
bar_val is <% $m->bar_val %>
% } else {
this request cannot ->bar_val!
% }
EOF
                      expect => <<'EOF',
foo_val is 77
bar_val is 42
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'lexer_subclass',
                      description => 'use a HTML::Mason::Lexer subclass',
                      interp_params => { lexer_class => 'HTML::Mason::Lexer::Test',
                                         bar_val => 76 },
                      component => <<'EOF',
% my $lex = $m->interp->compiler->lexer;
% if ( $lex->can('bar_val') ) {
bar_val is <% $lex->bar_val %>
% } else {
this lexer cannot ->bar_val!
% }
EOF
                      expect => <<'EOF',
bar_val is 76
EOF
                    );

#------------------------------------------------------------

    # We don't use object files, because we want to catch the output
    # of compiled_component() instead of writing it to a file
    $group->add_test( name => 'compiler_subclass',
                      description => 'use a HTML::Mason::Compiler subclass',
                      interp_params => { compiler_class => 'HTML::Mason::Compiler::ToObject::Test',
                                         use_object_files => 0,
                                         baz_val => 75 },
                      component => <<'EOF',
baz is !!BAZ!!
EOF
                      expect => <<'EOF',
baz is 75
EOF
                    );

#------------------------------------------------------------

    return $group;
}

