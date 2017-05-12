package HTML::TurboForm::Constraint::Date;
use warnings;
use strict;
use Date::Calc qw/check_date/;
use base qw(HTML::TurboForm::Constraint);

sub check{
  my ($self)=@_;
  my $result=0;

  my $day='';
  my $month='';
  my $year='';
  my $request=$self->request;

  $day=$request->{$self->{name}.'_day'};# if (exists($request->{$self->{name}.'_day'}));
  $month=$request->{$self->{name}.'_month'};# if (exists($request->{$self->{name}.'_month'}));
  $year=$request->{$self->{name}.'_year'};# if (exists($request->{$self->{name}.'year'})) ;

  return 1 if( check_date( $year,$month,$day ) );
  return 0;  
}

sub message{
  my ($self)=@_;
  return $self->{text};
}

1;

__END__

=head1 HTML::TurboForm::Constraint::Date

Representation class for Date constraint.

=head1 DESCRIPTION

Straight forward so no need for much documentation.
See HTML::TurboForm doku for mopre details.

=head1 METHODS

=head2 check

Arguments: none

returns 1 if valid, otherwise 0.

=head1 AUTHOR

Thorsten Domsch, tdomsch@gmx.de

=cut


