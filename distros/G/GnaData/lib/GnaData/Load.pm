
use strict;
use LWP::UserAgent;
use LWP::Protocol::https;
use HTTP::Cookies;
use HTTP::Request::Common;
use HTML::LinkExtor;
use URI::URL;
use IO::Handle;
use English;


=pod
GnaData::Load::Agent is a subclass of the LWP::UserAgent which allows
redirects for POST requests
=cut

package GnaData::Load::Agent;
@GnaData::Load::Agent::ISA = qw(LWP::UserAgent);


sub redirect_ok {
    return 1;
}


package GnaData::Load;

sub new {
    my $proto = shift;
    my $class =  ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->{'agent'} = GnaData::Load::Agent->new();
    $self->{'sleep'} = 1; 	
    $self->{'cookie_jar'} = HTTP::Cookies->new();
    $self->{'agent'}->cookie_jar($self->{'cookie_jar'});
    $self->{'found'} = {};

    $self->{'output_handle'} = IO::Handle->new();
    $self->{'output_handle'}->fdopen(fileno(STDOUT), "w");

    return $self;
}

sub load {
  my $self = shift;
  my $get = shift;
  my $post = shift;
  my ($returnval) = "";

  if (defined($post)) {
      my $req = HTTP::Request::Common::POST($get, $post);
      my $res = $self->{'agent'}->request($req);
      $self->{'reply'} =  $res->as_string;
      $self->{'base'} = $res->base;
      sleep($self->{'sleep'});
  } elsif (defined($get)) {
      my $req = new HTTP::Request 'GET', $get;
      my $res = $self->{'agent'}->request($req);
      $self->{'reply'} =  $res->as_string;
      $self->{'base'} = $res->base;
      sleep($self->{'sleep'});
  }
  return $self->{'reply'};
}

sub reply {
    my ($self) = @_;
    return $self->{'reply'};
}

my (@currentlinks) = ();

sub callback {
    my($tag, %attr) = @_;
    local($_);
    return if ($tag ne 'a' && $tag ne 'frame'); # we only look closer at <img ...>
    foreach (values %attr) {
	if (!/^mailto:/) {
	    s/\#.*?$//; 
	    push (@currentlinks, $_);
	}
    }
}

my($p) = HTML::LinkExtor->new(\&callback);

sub extract_hrefs {
    my $self = shift;
    my $regexp = shift;
    @currentlinks = ();
    $p->parse($self->{'reply'});
	
    @currentlinks = map { $_ = URI::URL::url($_, $self->{'base'})->abs; } 
    @currentlinks;
    if (defined($regexp) &&
	$regexp ne "") {
	@currentlinks = grep (/$regexp/, @currentlinks);
    }
    return (@currentlinks);
}

sub extract_data {
    my $self = shift;
    my $regexp = shift;
    my $replyin = shift;
    my (@returnval);
    my ($reply) = defined($replyin) ? $replyin :
	$self->{'reply'};
    while ($reply =~ m/$regexp/is) {
	push (@returnval, $1);
	$reply = $::POSTMATCH;
    }
    return @returnval;
}

sub dump_links {
    my ($self, @list) = @_;
    my ($href);
    foreach $href (@list) {
	if ($self->{'found'}->{$href} != 1) {
	    $self->{'found'}->{$href} = 1;
	    $self->print (">> $href\n");
	    $self->print ( $self->load($href));
	    $self->flush();
	}
    }
}

sub print {
    my ($self, $s) = @_;
    $self->{'output_handle'}->print($s);
}

sub flush {
    my ($self, $s) = @_;
    $self->{'output_handle'}->flush();
}



sub output_handle {
    my ($self, $outh) = @_;
    $self->{'output_handle'} = $outh;
}

sub extract_cycle {
    my ($self, $href, $elements, $cycle_regexp, 
	$extract_regexp, $row) = @_; 
    my (@courselist) = ();
    my ($pageindex) = 1;
    while (1) {
	my (%hash) = %$elements;
	$hash{$row} = $pageindex;
	my ($reply) = 
	    $self->load($href, \%hash);
	push (@courselist, 
	      $self->extract_hrefs($extract_regexp));
	      if ($reply =~ /$cycle_regexp/i) {
		  print "# Found next", "\n";
		  $pageindex += $1;
	      } else {
		  last;
	      }
    }
    return @courselist;
}


=pod
Backward conpatibility with GnaCatalog::Load
=cut

sub extract {
    print STDERR "Warning: extract is depreciated, use extract_hrefs";
    my ($self, $get, $post);
    $self->load($get, $post);
    return $self->extract_hrefs();
}

=pod
Backward conpatibility with GnaCatalog::Load
=cut

package GnaCatalog::Load;
@GnaCatalog::Load::ISA = qw(GnaData::Load);

sub new {
    print STDERR "Warning: GnaCatalog::Load is depreciated use GnaCatalog::Load";
    return GnaCatalog::Load::new(@_);
}

1;













