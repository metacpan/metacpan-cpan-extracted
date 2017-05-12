package HTML::Puzzle::Format;

require 5.005;

$VERSION 			= "0.12";
sub Version 		{ $VERSION; }

use Carp;
#use warnings;
use FileHandle;
use vars qw($DEBUG $DEBUG_FILE_PATH);
use strict;
use HTML::Template::Extension;
use HTML::Puzzle::DBTable;

$DEBUG 				= 0;
$DEBUG_FILE_PATH	= '/tmp/HTML-Puzzle-Format.debug.txt';

my %fields 	=
			    (
				 items 		=> [],
				 dbh 		=> undef,
				 tablename 	=> undef,
				 filename 	=> undef,
				 opt_items 	=> {},
				 order		=> undef,
				 date_format	=> '%Y-%m-%d',
				 filter		=> [],   
			     );
     
my @fields_req	= qw/filename/;
my $DEBUG_FH;     

sub new
{   
	my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self,$class;
    $self->_init(@_);
    return $self;
}							

sub _init {
	my $self = shift;
	my (%options) = @_;
	# set debug mode on parent modules
	$HTML::Puzzle::Template::DEBUG = $DEBUG;
	$HTML::Puzzle::DBTable::DEBUG = $DEBUG;
	$DEBUG_FH = new FileHandle ">>$DEBUG_FILE_PATH" if ($DEBUG);	
	# set local debug mode
	# Assign default options
	while (my ($key,$value) = each(%fields)) {
		$self->{$key} = $self->{$key} || $value;
    }
    # Assign options
    while (my ($key,$value) = each(%options)) {
    	$self->{$key} = $value
    }
    # Check required params
    foreach (@fields_req) {
		croak "You must declare '$_' in " . ref($self) . "::new"
				if (!defined $self->{$_});
	}
	# filter should be an array if it's not already
  	if (defined $self->{filter} && ref($self->{filter}) ne 'ARRAY') {
    	$self->{filter} = [ $self->{filter} ];
  	}
	if (defined $self->{dbh} && defined $self->{tablename}) {
		# internal autofilled items
		my $dbT	= new HTML::Puzzle::DBTable(    dbh     => $self->{dbh},
                                                name    => $self->{tablename},
						date_format => $self->{date_format}
                                            );
        $self->{items}	= $dbT->hash_items(undef,$self->{order});
	}									
}

sub html {
	my $self = shift;
	my $tmpl = new HTML::Template::Extension (  'filename' => $self->{filename},
												'autoDeleteHeader' => 1 ,
												'plugins' => ["SLASH_VAR",
														 	 "HEAD_BODY"]);
	my $items = $self->{items};
	# handle items filters if necessary
  	$self->_call_filters(\$items) if @{$self->{filter}};
	$tmpl->param('items' => $items);
	foreach (keys(%{$self->{opt_items}})) {
		$tmpl->param($_ => $self->{opt_items}->{$_});
	}
	return $tmpl->html;
}

sub _call_filters {
  my $self = shift;
  my $items_ref = shift;

  my ($format, $sub);
  foreach my $filter (@{$self->{filter}}) {
    croak("HTML::Puzzle->new() : bad value set for filter parameter - must be a code ref or a hash ref.")
      unless ref $filter;

    # translate into CODE->HASH
    $filter = { 'format' => 'scalar', 'sub' => $filter }
      if (ref $filter eq 'CODE');

    if (ref $filter eq 'HASH') {
      $format = $filter->{'format'};
      $sub = $filter->{'sub'};

      # check types and values
      croak("HTML::Puzzle->new() : bad value set for filter parameter - hash must contain \"format\" key and \"sub\" key.")
        unless defined $format and defined $sub;
      croak("HTML::Puzzle->new() : bad value set for filter parameter - \"format\" must be either 'array' or 'scalar'")
        unless $format eq 'array' or $format eq 'scalar';
      croak("HTML::Puzzle->new() : bad value set for filter parameter - \"sub\" must be a code ref")
        unless ref $sub and ref $sub eq 'CODE';

      # catch errors
      eval {
        if ($format eq 'scalar') {
          # call
          $sub->($items_ref);
        } else {
	  # modulate
	  my @array = map { $_."\n" } split("\n", $$items_ref);
          # call
          $sub->(\@array);
	  # demodulate
	  $$items_ref = join("", @array);
        }
      };
      croak("HTML::Puzzle->new() : fatal error occured during filter call: $@") if $@;
    } else {
      croak("HTML::Puzzle->new() : bad value set for filter parameter - must be code ref or hash ref");
    }
  }
  # all done
  return $items_ref;
}

sub DESTROY {
	$DEBUG_FH->close if ($DEBUG);
}

sub items { my $s=shift; return @_ ? ($s->{items}=shift) : $s->{items} }
sub order { my $s=shift; return @_ ? ($s->{order}=shift) : $s->{order} }
sub filename { my $s=shift; return @_ ? ($s->{filename}=shift) 
															: $s->{filename} }
sub opt_items { my $s=shift; return @_ ? ($s->{opt_items}=shift) 
															: $s->{opt_items} }
sub filter { my $s=shift; return @_ ? ($s->{filter}=shift) 
															: $s->{filter} }

# Preloaded methods go here.

1;
__END__
