package Mock::WWW::Mechanize;

use warnings 'all';
use strict;

use Carp;
use File::Spec;
use URI;
use POSIX;
use Compress::Zlib;
use WWW::Mechanize;

use base 'Test::MockObject';
 
sub new
{
  my $class = shift;
  my $self = $class->SUPER::new();
  my $mock_pages_root = shift || 't/pages';
  croak "$mock_pages_root: no such directory" if not -d $mock_pages_root;
  {
    no strict 'refs';
    undef *{'LWP::UserAgent::simple_request'};
    *{'LWP::UserAgent::simple_request'} = \&_simple_request;
  }
  my %subs;
  foreach my $sub (qw(add_header agent_alias back base click click_button
                      clone content ct current_form delete_header die dump_all
                      dump_forms dump_images dump_links field find_all_images
                      find_all_inputs find_all_links find_all_submits
                      find_image find_link follow_link form_name form_number
                      form_with_fields forms get images is_html
                      known_agent_aliases links put quiet redirect_ok reload
                      request res response save_content select set_fields
                      set_visible stack_depth status submit submit_form
                      success tick title untick update_html uri value warn)) {
    no strict 'refs';
    my $old_sub;
    eval "\$old_sub = \\&WWW::Mechanize::$sub";
    $subs{$sub} = sub { $self->log_call($sub, @_);
                        return &$old_sub(@_);
                      };
  }
  my $old_new = \&WWW::Mechanize::new;
  $subs{new} = sub { $self->log_call('new', @_);
                     my $self = &$old_new(@_);
                     $self->{_mock_pages_root} = $mock_pages_root;
                     return $self
                   };
  $self->fake_module('WWW::Mechanize', %subs);
  return $self;
}

sub _simple_request
{
  my ($self, $request, $arg, $size) = @_;
  my $uri = URI->new($request->uri);
  my $cache_path = File::Spec->catfile($self->{_mock_pages_root}, $uri->host, $uri->path);
  $cache_path .= '?'.$uri->query if $uri->query;
  $cache_path =~ s/\%2F/_/gi; # forward slash
  $cache_path =~ s/\%5C/_/gi; # backslash
  $cache_path =~ s/\%(..)/chr(hex($1))/ge;
  $cache_path .= '.gz';
  my $gz = gzopen($cache_path, 'rb')
    or croak "$cache_path: $gzerrno";
  my $content = "";
  my $buffer;
  $content .= $buffer while $gz->gzread($buffer) > 0;
  croak "Error reading from $cache_path: $gzerrno"
    if $gzerrno != Z_STREAM_END;
  $gz->gzclose() ;

  my $response = HTTP::Response->new(200, 'OK');
  $response->header(Connection => 'close');
  $response->header(Date => POSIX::strftime("%a, %d %b %Y %H:%M:%S %Z", gmtime));
  $response->header(Content_Type => 'text/html');
  $response->content($content);
  $response->request($request);
  return $response;
}

1;
