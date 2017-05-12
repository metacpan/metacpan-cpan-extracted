package HTTPD::ADS::Times;
use strict;
use warnings;
use Date::Calc qw(Normalize_DHMS Add_Delta_YMDHMS System_Clock Today_and_Now Gmtime );

BEGIN {
  use Exporter ();
  use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
  $VERSION     = 0.1;
  @ISA         = qw (Exporter);
  #Give a hoot don't pollute, do not export more than needed by default
  @EXPORT      = qw (gmttimestamp pgtimewindow);
  @EXPORT_OK   = qw ();
  %EXPORT_TAGS = ();
}

################################################ subroutine header begin ##

=head2 gmttimestamp

    Usage     : $timestamp = &gmttimestamp;
    Purpose   : Get the current time in GMT as an SQL-compatible timestampe w/o timezone
    Returns   : a string with a timestamp in GMT "yyyy:mm:dd:hh:mm:ss"
    Argument  : nothing
    Throws    : nothing
    Comments  : This is a sample subroutine header.
    : It is polite to include more pod and fewer comments.

    See Also   :

=cut

################################################## subroutine header end ##
sub gmttimestamp  {
    my ($year,$month,$day,$hour,$min,$sec)= Gmtime();
    return "$year-$month-$day $hour:$min:$sec";
}

################################################ subroutine header begin ##

=head2 pgtimewindow

    Usage     : How to use this function/method
    Purpose   : What it does
    Returns   : What it returns
    Argument  : What it wants to know
    Throws    : Exceptions and other anomolies
    Comments  : This is a sample subroutine header.
    : It is polite to include more pod and fewer comments.

    See Also   :

=cut

################################################## subroutine header end ##
sub pgtimewindow {
    my $self = shift;
    my @timestamp= Gmtime;
    #    my ($year,$month,$day,$hour,$min,$sec,$doy,$dow,$dst)= Gmtime();
    my $ref =  $self->normalizedIDSTimeWindowSize;
    $ref = $$ref;
    my ($target_year,$target_month,$target_day,$target_hour,$target_min,$target_sec) =
	Add_Delta_YMDHMS(@timestamp[0..5], @$ref);
    my $result = "$target_year-$target_month-$target_day $target_hour:$target_min:$target_sec";
}

1;
__END__
