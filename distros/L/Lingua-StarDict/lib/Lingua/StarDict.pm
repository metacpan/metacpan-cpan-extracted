package Lingua::StarDict;

use 5.008004;
use strict;
use warnings;


our $VERSION = '1.00';

require XSLoader;
XSLoader::load('Lingua::StarDict', $VERSION);

# Preloaded methods go here.




1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lingua::StarDict - Perl interface to the StarDict



=head1 SYNOPSIS

  use Lingua::StarDict;

  my $sd = new StarDict;
  # or
  my $sd = new StarDict( dict => "path_to_dictionary.ifo" );
  
  
  my $dicts  = $sd->dictionaries;
  my $result = $sd->search("word");
  
  

=head1 DESCRIPTION

Lingua::StarDict allows you to translate words via StarDict library and its dictionaries.
This module is only an interface, so your should install the StarDict before.
Full StarDict (with GUI and a lot of dependeces on GNOME libraries) can be found at
L<http://stardict.sourceforge.net> 
and the console version SDCV - StarDict console version (without depencies on GNOME) - here 
L<http://sdcv.sourceforge.net>


=over 4

=head2 B<Methods>


=item dictionaries

returns the reference to an array of hashes. 
    
  use Lingua::StarDict;
  use Data::Dumper;
  my $sd = new Lingua::StarDict;
  print Dump( $sd->dictionaries );

  $VAR1 = 
    [
      {
        'wordcount' => 110339,
        'ifofile' => '/usr/share/stardict/dic/en-ru-bars.ifo',
        'bookname' => 'en-ru-bars'
      },
      ...
    ];



=item search(C<some_word>)

Search an translation for the given word.
Returns the reference to an array of hashes.

  print Dump( $sd->search("some_word") );
  $VAR1 = 
    [
      {
        'explanation' => 'some_word explanation',
        'bookname' => 'dictionary name', # dictionary name where it was found
        'definition' => 'some_word definition'
      },
      ...
    ];



=head1 SEE ALSO


B<StarDict>
    L<http://stardict.sourceforge.net/>

B<SDCV> 
    StarDict console version without dependencies on a GNOME libraries. 
    L<http://sdcv.sourceforge.net/>


=head1 AUTHOR

Suhanov Vadim E<lt>suhanov_vadim@mail.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Suhanov Vadim

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
