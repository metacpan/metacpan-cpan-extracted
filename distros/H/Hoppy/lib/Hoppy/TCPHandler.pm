package Hoppy::TCPHandler;
use strict;
use warnings;

sub Hoppy::TCPHandler::import {
    my $package = ( caller() )[0];
    eval <<"    END";
        package $package;
        # load the handler packages
        use Hoppy::TCPHandler::Input;
        use Hoppy::TCPHandler::Connected;
        use Hoppy::TCPHandler::Disconnected;
        use Hoppy::TCPHandler::Error;
        use Hoppy::TCPHandler::Send;
    END
}

1;
__END__

=head1 NAME

Hoppy::TCPHandler - multi-declaration of TCPHandler classes.

=head1 SYNOPSIS

  use Hoppy::TCPHandler;

=head1 DESCRIPTION

"use Hoppy::TCPHandler" works same as bellows.

  use Hoppy::TCPHandler::Input;
  use Hoppy::TCPHandler::Connected;
  use Hoppy::TCPHandler::Disconnected;
  use Hoppy::TCPHandler::Error;
  use Hoppy::TCPHandler::Send;

=head1 METHODS

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
