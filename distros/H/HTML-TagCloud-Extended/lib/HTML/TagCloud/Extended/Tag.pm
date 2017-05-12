package HTML::TagCloud::Extended::Tag;
use strict;
use base qw/Class::Accessor::Fast/;
use Time::Local;
use HTML::TagCloud::Extended::Exception;

__PACKAGE__->mk_accessors(qw/name url count epoch/);

sub new {
    my $class = shift;
    my $self  = bless { }, $class;
    $self->_init(@_);
    return $self;
}

sub _init {
    my ($self, %args) = @_;
    my $epoch = $self->_timestamp2epoch($args{timestamp});
    $self->name(  $args{name}  || '' );
    $self->url(   $args{url}   || '' );
    $self->count( $args{count} || 0  );
    $self->epoch( $epoch             );
}

sub _timestamp2epoch {
    my ($self, $timestamp) = @_;
    if($timestamp) {
        my($year, $month, $mday, $hour, $min, $sec);
        if($timestamp =~ /^(\d{4})[-\/]{0,1}(\d{2})[-\/]{0,1}(\d{2})\s{0,1}(\d{2}):{0,1}(\d{2}):{0,1}(\d{2})$/) {
            $year  = $1;
            $month = $2;
            $mday  = $3;
            $hour  = $4;
            $min   = $5;
            $sec   = $6;
        } else {
            HTML::TagCloud::Extended::Exception->throw(qq/
                Wrong timestamp format "$timestamp".
            /);
        }
        my $epoch = timelocal($sec, $min, $hour, $mday, $month - 1, $year - 1900);
        return $epoch;
    } else {
        return time;
    }
}
1;
__END__

