package IDCHECKIO::ResponseIDCIO;

use strict;

our $VERSION = '0.01';

sub new {
  my $class = shift;
  my $self = {
    _status     => shift,
    _uid        => shift,
    _body       => shift,
  };

  my $defaultScheme = { 'analysisRefUid' => '',
                        'uid'            => '',
                        'mrz'            => {
                            'line2'      => '',
                            'line1'      => ''},
                        'holderDetail'   => {
                            'birthPlace' => '',
                            'firstName'  => (''),
                            'lastName'   => (''),
                            'address'    => '',
                            'birthDate'  => {
                                'year'   => '',                                            
                                'day'    => '',
                                'month'  => ''},
                            'gender'     => '',
                            'nationality'=> ''},
                        'documentDetail' => {
                            'emitCountry'=> '',
                            'extraInfos' => ({
                                'dataKey'=> '',
                                'dataValue'=> '',
                                'title'  => ''}),
                            'documentNumber'=> '',
                            'emitDate'   => {
                                'year'   => '',
                                'month'  => '',
                                'day'    => ''},
                            'expirationDate'=> {
                                'year'   => '',
                                'month'  => '',
                                'day'    => ''}},
                        'checkReportSummary'=> {
                            'check'      => ({
                                'titleMsg'=> '',
                                'identifier'=> '',
                                'result' => '',
                                'resultMsg'=> ''})},
                        'documentClassification'=> {
                            'idType'     => ''},
                        'report'         => '',
                        'accepted'       => '',
                        'started'        => '',
                        'ended'          => '',
                        'redirectUrl'    => ''};

  $self->{_body} = schemeCompliant( $self->{_body}, $defaultScheme );

  bless $self, $class;
  return $self;
}

sub schemeCompliant {
  my ( $dic, $scheme ) = @_;
  my $result = {};
  
  foreach my $key (sort(keys $dic)) {
    my $ref = ref($dic->{$key});
    if (ref($dic->{$key}) eq "SCALAR" or ref($dic->{$key}) eq "ARRAY") {
      if ( exists($scheme->{$key}) ) {
        $result->{$key} = $dic->{$key};
      }
    }
    elsif (ref($dic->{$key}) eq "HASH") {
      if ( exists($scheme->{$key}) ) {
        $result->{$key} = schemeCompliant($dic->{$key}, $scheme->{$key});
      }
    }
    unless ( ref($dic->{$key}) ) {
      if ( exists($scheme->{$key}) ) {
        $result->{$key} = $dic->{$key};
      }
    }
  }
  return $result;
}

sub get_status {
  my $self = shift;
  return $self->{_status};
}

sub get_uid {
  my $self = shift;
  return $self->{_uid};
}

sub get_body {
  my $self = shift;
  return $self->{_body};
}

1;
