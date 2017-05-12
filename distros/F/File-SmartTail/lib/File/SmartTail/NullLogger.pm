package File::SmartTail::Logger;
#
# $Id: NullLogger.pm,v 1.6 2008/07/09 20:40:20 mprewitt Exp $
#
# This file or one of the other loggers is copied to File::SmartTail/Logger.pm
# during the 'perl Makefile.PL' process.  Do not edit File::SmartTail/Logger.pm
# directly.  Edit one of the other Loggers and run make.
#
# DMJA, Inc <smarttail@dmja.com>
# 
# Copyright (C) 2003-2008 DMJA, Inc, File::SmartTail comes with 
# ABSOLUTELY NO WARRANTY. This is free software, and you are welcome to 
# redistribute it and/or modify it under the same terms as Perl itself.
# See the "The Artistic License" L<LICENSE> for more details.
#


{
    my $v;
    sub LOG {
        $v and return $v;

        $v = _init_log();

        return $v;
    }
}

sub _init_log {
    my $type = __PACKAGE__;
    my $self = {};
    bless $self, ref $type || $type;
    return $self;
}

sub debug { return undef; }
sub info { return undef; }
sub fatal { return undef; }
sub warn { return undef; }
sub error { return undef; }

sub logdie {
    my $self = shift;

    die "@_";
}

1;
