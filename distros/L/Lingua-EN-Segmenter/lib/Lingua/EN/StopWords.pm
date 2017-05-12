package Lingua::EN::StopWords;

=head1 NAME

Lingua::EN::StopWords - Typical stop words for an English corpus

=head1 SYNOPSIS

  use Lingua::EN::StopWords qw(%StopWords);
  
  my @words = ...;
  
  # Print non-stopwords in @words
  print join " ", grep { !$StopWords{$_} } @words; 
  
=head1 DESCRIPTION
    
See synopsis.

=head1 AUTHORS
    
David James <splice@cpan.org>
    
The stopword list was taken from 
L<http://www.askeric.org/Eric/Help/stop.shtml> 
(The original stopword list was in the public domain)

=head1 SEE ALSO
    
L<Lingua::EN::Segmenter::TextTiling>,  L<Lingua::EN::Segmenter::Baseline>, 
L<Lingua::EN::Segmenter::Evaluator>, L<http://www.cs.toronto.edu/~james>

=head1 LICENSE

  Copyright (c) 2002 David James
  All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
  
=cut

@EXPORT_OK = qw(%StopWords);
$VERSION = 0.10;
use base 'Exporter';

%StopWords = map { lc $_, 1 } qw(
a about above across adj after again against all almost alone along also 
although always am among an and another any anybody anyone anything anywhere 
apart are around as aside at away be because been before behind being below 
besides between beyond both but by can cannot could deep did do does doing done 
down downwards during each either else enough etc even ever every everybody 
everyone except far few for forth from get gets got had hardly has have having 
her here herself him himself his how however i if in indeed instead into inward 
is it its itself just kept many maybe might mine more most mostly much must 
myself near neither next no nobody none nor not nothing nowhere of off often on 
only onto or other others ought our ours out outside over own p per please plus 
pp quite rather really said seem self selves several shall she should since so 
some somebody somewhat still such than that the their theirs them themselves 
then there therefore these they this thorough thoroughly those through thus to 
together too toward towards under until up upon v very was well were what 
whatever when whenever where whether which while who whom whose will with
within without would yet young your yourself );

1;
