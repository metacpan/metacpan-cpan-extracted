# $Id: Text.pm,v 1.2 2003/01/16 19:41:31 lstein Exp $
package HTTPD::GroupAdmin::Text;
use Carp ();
use strict;
use vars qw(@ISA $DLM $VERSION $LineMax);
@ISA = qw(HTTPD::GroupAdmin);
$VERSION = (qw$Revision: 1.2 $)[1];
$DLM = ": ";

# Maximum size of each line in the group file.  Anytime we have more 
# group data than this we split it up into multiple lines.  At least 
# Apache 1.3.4 this limitation on lines in the group file.
$LineMax = 8 * 1024;

my %Default = (PATH => ".", 
	       DB => ".htgroup", 
	       FLAGS => "rwc",
	       );

sub new {
    my($class) = shift;
    my $self = bless { %Default, @_ } => $class;
    #load the DBM methods
    $self->load("HTTPD::GroupAdmin::DBM");
    $self->db($self->{DB}); 
    return $self;
}

sub _tie {
    my($self) = @_;
    my($fh,$db) = ($self->gensym(), $self->{DB});
    my($key,$val);
    printf STDERR "%s->_tie($db)\n", $self->class if $self->debug;

    $db =~ /^([^<>;|]+)$/ or Carp::croak("Bad file name '$db'"); $db = $1; #untaint	
    open($fh, $db) or return; #must be new

    while(<$fh>) {
	($key,$val) = $self->_parseline($fh, $_);
	next unless $key =~ /\S/;
	$self->{'_HASH'}{$key} = (exists $self->{'_HASH'}{$key} ?
				  join(" ", $self->{'_HASH'}{$key}, $val) :
				  $val);
    }
    CORE::close $fh;
}

sub _untie {
    my($self) = @_;
    return unless exists $self->{'_HASH'};
    $self->commit;
    delete $self->{'_HASH'};
}

DESTROY {
    $_[0]->_untie('_HASH');
    $_[0]->unlock;
}

sub commit {
     my($self) = @_;
     return if $self->readonly;
     my($fh,$db) = ($self->gensym(), $self->{DB});
     my($key,$val);

     $db =~ /^([^<>;|]+)$/ or return (0, "Bad file name '$db'"); $db = $1; 
#untaint
     my $tmp_db = "$db.$$"; # Use temp file until write is complete.
     open($fh, ">$tmp_db") or return (0, "open: '$tmp_db' $!");

     while(($key,$val) = each %{$self->{'_HASH'}}) {
         print $fh $self->_formatline($key,$val)
            or return (0, "print: '$tmp_db' failed: $!");
     }
     CORE::close $fh
        or return (0, "close: '$tmp_db' failed: $!");
     my $mode = (stat $db)[2];
     chmod $mode, $tmp_db if $mode;
     rename( $tmp_db,$db )
        or return (0, "rename '$tmp_db' to '$db' failed: $!");
     1;
}
sub _parseline {
    my($self,$fh) = (shift,shift);
    local $_ = shift;
    chomp; s/^\s+//; s/\s+$//;
    my($key, $val) = split(/:\s*/, $_, 2);
    $val =~ s/\s* \s*/ /g;
    return ($key,$val);
}

sub _formatline {
    my($self,$key,$val) = @_;
    my( $FieldMax ) = $LineMax - length( $key );
    my( @fields );
    $val =~ s/(\w) /$1 /g;
    while( length( $val ) > $FieldMax ) {
      my( $tail, $field );
      $field = substr( $val, 0, $FieldMax );
      $val = substr( $val, $FieldMax );
      ( $field, $tail ) = ( $field =~ m/^(.+) (\S+ ?)$/ );
      $val = $tail . $val;
      push( @fields, $field );
    }
    map( join($DLM, $key,$_) . "\n", @fields, $val );
}

sub add {
    my $self = shift;
    return(0, $self->db . " is read-only!") if $self->readonly;
    $self->HTTPD::GroupAdmin::DBM::add(@_);
}

package HTTPD::GroupAdmin::Text::_generic;
use vars qw(@ISA);
@ISA = qw(HTTPD::GroupAdmin::Text
	  HTTPD::GroupAdmin::DBM);

1;

__END__
