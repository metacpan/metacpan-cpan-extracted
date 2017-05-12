=head1 NAME

Log::Handler::Plugin::Config::Properties - Config loader for Config::Properties.

=head1 SYNOPSIS

    use Log::Handler::Plugin::Config::Properties;

    my $config = Log::Handler::Plugin::Config::Properties->get_config( $config_file );

=head1 ROUTINES

=head2 get_config()

Expect the config file name and returns the config as a reference.

The configuration uses full stops "." as a delimiter.

=head1 CONFIG STYLE

    file.mylog.reopen = 1
    file.mylog.fileopen = 1
    file.mylog.maxlevel = info
    file.mylog.permissions = 0640
    file.mylog.mode = append
    file.mylog.timeformat = %b %d %H:%M:%S
    file.mylog.debug_mode = 2
    file.mylog.minlevel = warn
    file.mylog.filename = example.log
    file.mylog.newline = 1
    file.mylog.message_layout = %T %H[%P] [%L] %S: %m

=head1 PREREQUISITES
    
    Config::Properties

=head1 EXPORTS
    
No exports.
    
=head1 REPORT BUGS
    
Please report all bugs to <jschulz.cpan(at)bloonix.de>.

If you send me a mail then add Log::Handler into the subject.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 COPYRIGHT

Copyright (C) 2007-2009 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Log::Handler::Plugin::Config::Properties;

use strict;
use warnings;
use Config::Properties;

our $VERSION = '0.03';
our $SPLITTOTREE = qr/\./;

sub get_config {
    my ($class, $config_file) = @_;
    my $properties = Config::Properties->new();

    open my $fh, '<', $config_file or die "unable to open $config_file: $!";
    $properties->load($fh);
    close $fh;

    my $config = $properties->splitToTree($SPLITTOTREE);
    return $config;
}

1;
