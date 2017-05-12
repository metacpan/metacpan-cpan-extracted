# -*- perl -*-

package Bundle::Mail::IspMailGate;

$VERSION = '0.01';

1;

__END__

=head1 NAME

Bundle::Mail::IspMailGate - A bundle to install the IspMailGate

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::Mail::IspMailGate'>

=head1 CONTENTS

IO::Scalar

IO::Tee

Net::SMTP

Mail::Internet

Digest::MD5

MIME::Base64

MIME::Tools


=head1 DESCRIPTION

This bundle includes all that's needed to install the IspMailGate.
Usage:

  perl -MCPAN -e shell
  install Bundle::Mail::IspMailGate


=cut
