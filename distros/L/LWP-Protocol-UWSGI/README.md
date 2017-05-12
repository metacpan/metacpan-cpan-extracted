# LWP-Protocol-UWSGI
Implement UWSGI protocol for LWP

LWP::Protocol::UWSGI - uwsgi support for LWP

SYNOPSIS

  use LWP::Protocol::UWSGI;
  use LWP::UserAgent;
  $res = $ua->get("uwsgi://www.example.com");

DESCRIPTION

The LWP::Protocol::UWSGI module provide support for using uwsgi
protocol with LWP. 

This module unbundled with the libwww-perl.

SEE ALSO

LWP::UserAgent, LWP::Protocol

=head1 COPYRIGHT

Copyright 2015 Nikolas Shulyakovskiy.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

