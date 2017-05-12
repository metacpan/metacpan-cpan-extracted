###########################################
package Gaim::Log::Message;
###########################################
use strict;
use warnings;
use DateTime;
use DateTime::Format::Strptime;
use Log::Log4perl qw(:easy);

our @ACCESSORS = qw(from to protocol date content);
our $VERSION   = "0.04";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        %options,
    };

    $class->make_accessor($_) for @ACCESSORS;

    bless $self, $class;
}

##################################################
sub make_accessor {
##################################################
    my($package, $name) = @_;

    no strict qw(refs);

    my $code = <<EOT;
        *{"$package\\::$name"} = sub {
            my(\$self, \$value) = \@_;
    
            if(defined \$value) {
                \$self->{$name} = \$value;
            }
            if(exists \$self->{$name}) {
                return (\$self->{$name});
            } else {
                return "";
            }
        }
EOT
    if(! defined *{"$package\::$name"}) {
        eval $code or die "$@";
    }
}

###########################################
sub as_string {
###########################################
    my($self) = @_;

    return "$self->{from} =($self->{protocol})=> $self->{to}: [" .
           scalar(localtime($self->{date})) . "] [$self->{content}]";
}

1;

__END__

=head1 NAME

Gaim::Log::Message - Represents a logged Gaim message

=head1 SYNOPSIS

    use Gaim::Log::Message;

    my $msg = Gaim::Log::Message->new(
                from    => $from,
                to      => $to,
                date    => $date,
                content => $content,
    );

    print $msg->as_string(), "\n";

=head1 DESCRIPTION

Helper class to represent a gaim log message. The following accessors
are available:

=over 4

=item from()

User ID the message was sent from.

=item to()

User ID the message was sent to.

=item date()

Date in epoch seconds.

=item content()

Content of the message.

=back

=head2 Additional Methods

=over 4

=item $msg-E<gt>as_string()

Format all messages fields (from, to, date, content) and return the
result as a string.

=back

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
