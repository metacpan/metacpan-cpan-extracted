use strict;
use warnings;

use HTML::Mason::CGIHandler;
use CGI qw(-no_debug);  # Prevent "(offline mode: enter name=value pairs on standard input)"

{
    # This class simulates CGI requests.  It's rather ugly, it tries
    # to fool HTML::Mason::Tests into thinking that CGIHandler is a subclass of Interp.

    package CGITest;
    use HTML::Mason::Tests;
    use base 'HTML::Mason::Tests';

    sub _run_test
    {
        my $self = shift;
        my $test = $self->{current_test};

        $self->{buffer} = '';

        my %interp_params = ( exists $test->{interp_params} ?
                              %{ $test->{interp_params} } :
                              () );

        my $interp = HTML::Mason::CGIHandler->new
            (comp_root => $self->comp_root,
             data_dir  => $self->data_dir,
             %interp_params,
            );
        
        eval { local $CGI::LIST_CONTEXT_WARN = 0; $self->_execute($interp) };
        
        return $self->check_result($@);
    }

    sub _execute
    {
        my ($self, $interp) = @_;  # $interp is a CGIHandler object
        my $test = $self->{current_test};
        
        #print "Calling $test->{name} test with path: $test->{call_path}\n" if $DEBUG;
        $test->{pretest_code}->() if $test->{pretest_code};
        CGI::initialize_globals();     # make sure CGI doesn't cache previous query
        $ENV{REQUEST_METHOD} = 'GET';  # CGI.pm needs this, or it won't process args
        $ENV{PATH_INFO} = $test->{call_path};
        $ENV{QUERY_STRING} = join '=', @{$test->{call_args}};
        
        $interp->handle_request($self->{buffer});
    }
}

$ENV{DOCUMENT_ROOT} = CGITest->comp_root;

my $group = CGITest->new( name => 'cgi',
                          description => 'HTML::Mason::CGIHandler class',
                          interp_class => 'HTML::Mason::CGIHandler',
                        );

#------------------------------------------------------------

my $basic_header = "Content-Type: text/html";
$basic_header .= '; charset=ISO-8859-1' if CGI->can('charset');
$basic_header .= "${CGI::CRLF}${CGI::CRLF}";

$group->add_test( name => 'basic',
                  description => 'Test basic CGIHandler operation',
                  component => 'some text',
                  expect    => "${basic_header}some text",
                );

#------------------------------------------------------------

$group->add_test( name => 'dynamic',
                  description => 'Test CGIHandler operation with dynamic components',
                  component => 'some <% "dynamic" %> text',
                  expect    => "${basic_header}some dynamic text",
                );

#------------------------------------------------------------

$group->add_test( name => 'args',
                  description => 'Test CGIHandler operation with arguments',
                  call_args => [arg => 'dynamic'],
                  component => 'some <% $ARGS{arg} %> text',
                  expect    => "${basic_header}some dynamic text",
                );

#------------------------------------------------------------

$group->add_test( name => 'cgi_object',
                  description => 'Test access to the CGI request object',
                  call_args => [arg => 'boohoo'],
                  component => q{some <% $m->cgi_object->param('arg') %> cryin'},
                  expect    => "${basic_header}some boohoo cryin'",
                );

#------------------------------------------------------------

$group->add_test( name => 'fatal_error',
                  description => 'Test fatal error_mode',
                  interp_params => { error_mode => 'fatal', error_format => 'text' },
                  component => q{% die 'dead';},
                  expect_error => qr/dead at .+/,
                );

$group->add_test( name => 'headers',
                  description => 'Test header generation',
                  component => q{% $r->header_out('foo' => 'bar');},
                  expect    => qr/Foo: bar/i,
                );

$group->add_test( name => 'redirect_headers',
                  description => 'Test header generation',
                  component => q{% $m->redirect('/hello.html');},
                  expect    => qr/Status: 302\s+Location: \/hello\.html|Location: \/hello\.html\s+Status: 302/i,
                );

#------------------------------------------------------------

$group->run;

