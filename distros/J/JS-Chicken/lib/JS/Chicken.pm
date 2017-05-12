package JS::Chicken;

use strict;
use warnings;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:STEVAN';

1;

__END__

=head1 NAME

JS::Chicken - Templating module for Javascript

=head1 SYNOPSIS

  // simple Hello world example
  $('<div>Hello <span>Nobody</span></div>').process_template({
      'span' : "World"
  });

  // produces <div>Hello <span>World</span></div>

  // slightly more complex example
  $('<div>Hello <a href="#">Nobody</a></div>').process_template({
      'a' : new Chicken.Callback(function (tmpl, selector) {
          var target = tmpl.find(selector);
          target.attr({ href : 'http://www.world.com' });
          target.html("World")
      })
  });

  // produces <div>Hello <a href="http://www.world.com">World</a></div>

=head1 DESCRIPTION

                     ,--,                          ,--.                   ,--.
    ,----..        ,--.'|   ,---,  ,----..     ,--/  /|    ,---,.       ,--.'|
   /   /   \    ,--,  | :,`--.' | /   /   \ ,---,': / '  ,'  .' |   ,--,:  : |
  |   :     :,---.'|  : '|   :  :|   :     ::   : '/ / ,---.'   |,`--.'`|  ' :
  .   |  ;. /|   | : _' |:   |  '.   |  ;. /|   '   ,  |   |   .'|   :  :  | |
  .   ; /--` :   : |.'  ||   :  |.   ; /--` '   |  /   :   :  |-,:   |   \ | :
  ;   | ;    |   ' '  ; :'   '  ;;   | ;    |   ;  ;   :   |  ;/||   : '  '; |
  |   : |    '   |  .'. ||   |  ||   : |    :   '   \  |   :   .''   ' ;.    ;
  .   | '___ |   | :  | ''   :  ;.   | '___ |   |    ' |   |  |-,|   | | \   |
  '   ; : .'|'   : |  : ;|   |  ''   ; : .'|'   : |.  \'   :  ;/|'   : |  ; .'
  '   | '/  :|   | '  ,/ '   :  |'   | '/  :|   | '_\.'|   |    \|   | '`--'
  |   :    / ;   : ;--'  ;   |.' |   :    / '   : |    |   :   .''   : |
   \   \ .'  |   ,/      '---'    \   \ .'  ;   |,'    |   | ,'  ;   |.'
    `---`    '---'                 `---`    '---'      `----'    '---'

                           ,~.
                         ,-'__ `-,
                        {,-'  `. }              ,')
                       ,( a )   `-.__         ,',')~,
                      <=.) (         `-.__,==' ' ' '}
                        (   )                      /)
                         `-'\   ,                    )
                             |  \        `~.        /
                             \   `._        \      /
                              \     `._____,'    ,'
                               `-.             ,'
                                  `-._     _,-'
                                      77jj'
                                     //_||
                                  __//--'/`
                                ,--'/`  '


Chicken is a templating system written in Javascript using jQuery
to do structured DOM substitutions. This type of templating is
sometimes called "callback templating", because instead of the
template system pushing values into a template, you specify
a set of triggers or events which fire a callback, the result of
which is the template operation.

=head2 Chicken, WTF?!?!?

Well, here is how it happened.

  <me> Hey, what should I call my callback templating module?
  <chris> Hmmm
          ... callback templating
            ... Pull templates
              ... pullet -> 'Pull it'
                ... pullet being a term for "Chicken"
                  ... Call it Chicken!

So if you don't like the name, blame Chris.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut