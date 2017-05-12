package Mock::NatwestWebServer;

use strict;
use base qw/ Test::MockObject /;

use Carp;
use Digest::MD5;
use URI;

use constant POSS_PIN => [qw/ first second third fourth /];
use constant POSS_PASS => 
   [qw/ first second third fourth fifth sixth seventh eighth ninth tenth /,
    qw/ eleventh twelfth thirteenth fourteenth fifteenth sixteenth /,
    qw/ seventeenth eighteenth nineteenth twentieth /];
use constant STATUS => 
   { ok => 1, unavailable => 2, other_error => 3, unknown_page => 4,
     invalid_request_1 => 5, invalid_request_2 => 6 };
use constant PAGES =>
   { 'logon.asp' => 1, 
     'logon-pinpass.asp' => 1,
     'balances.asp' => 1,
     'logonmessage.asp' => 1,
   };

     

sub new{
   my ($class) = @_;

   my $self = $class->SUPER::new();
   
   $self->fake_module( 'LWP::UserAgent' );
   $self->fake_new( 'LWP::UserAgent' );

   $self->{scheme} = 'https';
   $self->{host} = 'www.nwolb.com';
   $self->{port} = 443;
   $self->{path_prefix} = [ 'secure' ];
   $self->{pin_desc} = 'PIN';

   $self->{accounts} = {};
   $self->{status} = STATUS->{ok};
   $self->{progress} = 0;
   $self->{response} = {};
   $self->{session} = undef;
   $self->{md5} = Digest::MD5->new();
   $self->{pin_sel} = undef;
   $self->{pin_lock} = 0;
   $self->{pass_sel} = undef;
   $self->{pass_lock} = 0;
   $self->{account} = undef;
   $self->{logonmessage} = 0;

   $self->mock('post', \&_post);
   $self->mock('is_success', sub { $_[0]->{response}{is_success} } );
   $self->mock('message', sub { $_[0]->{response}{message} } );
   $self->mock('content', sub { $_[0]->{response}{content} } );
   $self->mock('base', sub { return $_[0] } );
   $self->mock('as_string', 
      sub {
         local $, = '/';
         my $base = join('/', 
            $self->{scheme} . '://' . $self->{host}, 
             @{$_[0]->{response}{path_segments}}
                [1..$#{$_[0]->{response}{path_segments}}]
         );
	 $base .= '?' . $_[0]->{response}{query}
	    if exists $_[0]->{response}{query} and 
	       defined $_[0]->{response}{query};
         return $base;
      });
   $self->mock('path_segments', sub { @{$_[0]->{response}{path_segments}} } );
   $self->mock('query', sub { @{$_[0]->{response}{query}} } );

   return $self;
}


sub _post {
   my $self = shift;
   my $url = shift;
   my $args = shift;

   my $uri = URI->new(lc($url));

   return $self->_invalid_request(
      'URL missing'
   ) if length $uri->as_string == 0;

   return $self->_invalid_request(
      "Protocol scheme '" . $uri->scheme . "' not supported"
   ) if $uri->scheme ne $self->{scheme};

   return $self->_invalid_request(
      "Can't connect to " . $uri->host_port .
      " (Bad hostname '" . $uri->host . "')"
   ) if $uri->host_port ne $self->{host} . ':' . $self->{port};

   for (0..$#{$self->{path_prefix}}) {
      return $self->_unknown_page($uri)
         if !defined [$uri->path_segments]->[$_+1] or
	    [$uri->path_segments]->[$_+1] ne $self->{path_prefix}[$_];
   }

   my $offset = @{$self->{path_prefix}};
   
   if (defined PAGES->{($uri->path_segments)[$offset+1] || ''}) {
      $self->{session} = $self->{md5}->add(rand)->hexdigest;
      my @ps = $uri->path_segments;
      splice @ps, $offset+1, 0, $self->{session};
      $uri->path_segments( @ps );
   }

   return $self->_unknown_page($uri)
      if @{[$uri->path_segments]} != $offset+3;

   return $self->_session_expired($uri)
      if ($uri->path_segments)[$offset+1] ne ($self->{session} || '');

   return $self->_unknown_page($uri)
      if !defined PAGES->{($uri->path_segments)[$offset+2]};

   return $self
      if $self->_common_checks($uri, @_);

   my $url_sub = '_' . ($uri->path_segments)[$offset+2];
   $url_sub =~ s/\.asp$//;
   $url_sub =~ s/-/_/g;

   $self->$url_sub($uri, $args);

   return $self;
}

sub set_scheme { $_[0]->{scheme} = $_[1]; }
sub set_host { $_[0]->{host} = $_[1]; }
sub set_port { $_[0]->{port} = $_[1]; }
sub set_path_prefix { $_[0]->{path_prefix} = [ grep { $_ } split(m|/|,$_[1]) ]; }
sub set_pin_desc { $_[0]->{pin_desc} = $_[1]; }

sub add_account {
   my $self = shift;
   my %args = @_;

   croak "Must supply a date of birth, stopped" if !defined $args{dob};
   croak "Must supply a uid, stopped" if !defined $args{uid};
   croak "Must supply a pin, stopped" if !defined $args{pin};
   croak "Must supply a password, stopped" if !defined $args{pass};

   $self->{accounts}{$args{dob} . $args{uid}} = 
      { pin => $args{pin}, pass => $args{pass} };
}

sub expire_session {
   my $self = shift;

   undef $self->{session};
   $self->{progress} = 0;
   $self->clear_pinpass;
}

sub logonmessage_enable {
   my $self = shift;

   $self->{logonmessage} = 1;
}

sub logonmessage_disable {
   my $self = shift;

   $self->{logonmessage} = 0;
}

sub session_id { $_[0]->{session} }

sub set_pinpass {
   my $self = shift;
   my $pin = shift;
   my $pass = shift;
   
   $self->{pin_sel} = $pin;
   $self->{pin_lock} = 1;

   $self->{pass_sel} = $pass;
   $self->{pass_lock} = 1;
}

sub clear_pinpass {
   my $self = shift;

   $self->{pin_lock} = 0;
   $self->{pass_lock} = 0;
}

sub _invalid_request {
   my $self = shift;
   my $message = shift || 'Invalid request';

   $self->{response} = { is_success => 0, content => '', 
                         message => $message };
   
   return $self;
}

sub _unknown_page {
   my $self = shift;
   my $uri = shift;

   $self->_common_checks($uri, STATUS->{unknown_page});
   return $self;
}

sub _session_expired {
   my $self = shift;
   my $uri = shift;

   my @ps = $uri->path_segments;
   splice @ps, -1, 1, 'exit.asp';

   $self->{response} = { 
      is_success => 1, 
      content => '<html><body>Session expired</body></html>',
      path_segments => [ @ps ]
   };

   return $self;
}

sub _common_checks {
   my $self = shift;
   my $uri = shift;
   my $status = shift || $self->{status};

   return 0 if $status == STATUS->{ok}
            or $status == STATUS->{invalid_request_1}
            or $status == STATUS->{invalid_request_2};

   $self->{response} = {
      is_success => 1,
      path_segments => [ $uri->path_segments ],
      content => eval {
         return '<html><body>Service Temporarily Unavailable</body></html>'
            if $status == STATUS->{unavailable};

         return '<html><body><div class=ErrorMsg>Error</div></body></html>'
            if $status == STATUS->{other_error};

         return '<html><body>An unknown page</body></html>'
            if $status == STATUS->{unknown_page};
      }
   };

   return 1;
}

sub _pick_pin {
   my $self = shift;

   my @digits_choose = (0..3);
   $self->{pin_sel} = [];

   my $chosen;

   push @{$self->{pin_sel}}, 
      splice(@digits_choose, int(rand(scalar @digits_choose)), 1);
   push @{$self->{pin_sel}}, 
      splice(@digits_choose, int(rand(scalar @digits_choose)), 1);
   push @{$self->{pin_sel}}, 
      splice(@digits_choose, int(rand(scalar @digits_choose)), 1);
}

sub _pick_pass {
   my $self = shift;
   my $pass = shift;

   my @chars_choose = (0..(length $pass)-1);
   $self->{pass_sel} = [];

   my $chosen;

   push @{$self->{pass_sel}}, 
      splice(@chars_choose, int(rand(scalar @chars_choose)), 1);
   push @{$self->{pass_sel}}, 
      splice(@chars_choose, int(rand(scalar @chars_choose)), 1);
   push @{$self->{pass_sel}}, 
      splice(@chars_choose, int(rand(scalar @chars_choose)), 1);
}

sub _logon {
   my $self = shift;
   my $uri = shift;
   my $args = shift;

   my $args_ok = exists $args->{DBIDa} and exists $args->{DBIDb} and
                 exists $args->{radType} and exists $args->{scriptingon};

   $args_ok = 0 if $args_ok and $args->{scriptingon} ne 'yup';

   $args_ok = 0 if $args_ok and
      !exists $self->{accounts}{$args->{DBIDa} . $args->{DBIDb}};

   unless ($args_ok) {
      return $self if $self->_common_checks($uri, STATUS->{other_error});
   }

   my $content = '<html><body><p>Please enter the ';
   if ($self->{status} == STATUS->{invalid_request_1}) {
      $content .= 'first, third and tenth';
   } else {
      $self->_pick_pin() unless $self->{pin_lock};
      $content .= POSS_PIN->[$self->{pin_sel}[0]] . ', ' .
                  POSS_PIN->[$self->{pin_sel}[1]] . ' and ' .
                  POSS_PIN->[$self->{pin_sel}[2]]; 
   }
   $content .= ' digits from your ' . $self->{pin_desc} . ':</p>';
   $content .= '<p>Please enter the ';
   if ($self->{status} == STATUS->{invalid_request_2}) {
      $content .= 'first, third and thirtieth';
   } else {
      $self->_pick_pass(
         $self->{accounts}{$args->{DBIDa} . $args->{DBIDb}}{pass}
      ) unless $self->{pass_lock};
      $content .= POSS_PASS->[$self->{pass_sel}[0]] . ', ' .
                  POSS_PASS->[$self->{pass_sel}[1]] . ' and ' .
                  POSS_PASS->[$self->{pass_sel}[2]];
   };
   $content .= ' characters from your Password:</p></body></html>';
   
   $self->{response} = {
      is_success => 1,
      path_segments => [ $uri->path_segments ],
      content => $content
   };

   $self->{account} = $args->{DBIDa} . $args->{DBIDb};
   $self->{progress} = 1;
}   

sub _logon_pinpass {
   my $self = shift;
   my $uri = shift;
   my $args = shift;

   if ($self->{progress} != 1) {
      $self->_common_checks($uri, STATUS->{other_error});
      return $self;
   }

   my $args_ok = exists $args->{pin1} and exists $args->{pin2} and
                 exists $args->{pin3} and exists $args->{pass1} and
                 exists $args->{pass2} and exists $args->{pass2} and
                 exists $args->{buttonComplete} and
                 exists $args->{buttonFinish};

   $args_ok = 0 if $args_ok and $args->{buttonComplete} ne 'Submitted';
   $args_ok = 0 if $args_ok and $args->{buttonFinish} ne 'Finish';

   unless ($args_ok) {
      $self->_common_checks($uri, STATUS->{other_error});
      return $self;
   }

   if ($self->{status} == STATUS->{invalid_request_1} or
       $self->{status} == STATUS->{invalid_request_2}) {
      $self->_common_checks($uri, STATUS->{other_error});
      return $self;
   }

   my $pin_passed =
      join('', $args->{pin1}, $args->{pin2}, $args->{pin3} );
   my $pin_required =
      join('', 
         (split(//, $self->{accounts}{$self->{account}}{pin}))
            [ @{$self->{pin_sel}} ]
      );

   my $pass_passed =
      join('', $args->{pass1}, $args->{pass2}, $args->{pass3} );
   my $pass_required =
      join('', 
         (split(//, $self->{accounts}{$self->{account}}{pass}))
            [ @{$self->{pass_sel}} ]
      );

   if ($pin_passed ne $pin_required) {
      $self->_common_checks($uri, STATUS->{other_error});
      return $self;
   }

   if ($pass_passed ne $pass_required) {
      $self->_common_checks($uri, STATUS->{other_error});
      return $self;
   }

   my $content;
   if ($self->{logonmessage}) {
      $content = '<html><body>' .
                 '<form action="LogonMessage.asp" method="post">' .
                 'Some important logon message' .
                 '</form></body></html>';
   } else {
      $content = '<html><body>' .
   		 'Our records indicate the last time you used ' . 
		 'the service was:' .
		 '</body></html>';
   }
   
   $self->{response} = {
      is_success => 1,
      path_segments => [ $uri->path_segments ],
      content => $content
   };

   if ($self->{logonmessage}) {
      $self->{progress} = 2;
   } else {
      $self->{progress} = 3;
   }
}

sub _logonmessage {
   my $self = shift;
   my $uri = shift;
   my $args = shift;

   if ($self->{progress} != 2) {
      $self->_common_checks($uri, STATUS->{other_error});
      return $self;
   }

   my $args_ok = exists $args->{buttonOK};

   $args_ok = 0 if $args_ok and $args->{buttonOK} ne 'Next';

   unless ($args_ok) {
      $self->_common_checks($uri, STATUS->{other_error});
      return $self;
   }

   my $content = '<html><body>' .
   		 'Our records indicate the last time you used ' .
		 'the service was:' .
		 '</body></html>';

   $self->{response} = {
      is_success => 1,
      path_segments => [ $uri->path_segments ],
      content => $content
   };

   $self->{progress} = 3;
}

sub _balances {
   my $self = shift;
   my $uri = shift;
   my $args = shift;

   if ($self->{progress} != 3) {
      $self->_common_checks($uri, STATUS->{other_error});
      return $self;
   }

   if ($self->{status} == STATUS->{invalid_request_1} or
       $self->{status} == STATUS->{invalid_request_2}) {
      $self->_common_checks($uri, STATUS->{other_error});
      return $self;
   }

   my ($query) = $uri->query =~ /^(\d+)$/;

   if (!defined $query) {
      $self->_common_checks($uri, STATUS->{other_error});
      return $self;
   }

   if ($query > 1) {
      $self->expire_session();
      $self->_common_checks($uri, STATUS->{other_error});
      return $self;
   }

   $self->{response} = {
      is_success => 1,
      path_segments => [ $uri->path_segments ],
      content => $query == 0 ? _balances0() : _balances0(),
      query => $query
   };
}

sub _balances0 {
<<EOF;
<html><body>
<form>
<table>
<tr></tr>
<tr class='a'>
<td>  CURRENT</td>
<td><span>60-01-27</span><span>60123456</span></td>
<td>£100</td><td>£100</td>
</tr>
<tr class='a'>
<td>  STUDENT</td>
<td><span>60-01-27</span><span>60654321</span></td>
<td>-£250</td><td>£750</td>
</tr>
<tr></tr>
</table>
</form>
Mini statement - not coded yet
<div class="smftr">
</div>
</body></html>
EOF
}

1;
