package Devel::RingBuffer::ThreadFacade;

use threads;
use threads::shared;

use strict;
use warnings;

our $VERSION = '0.31';

sub tid { return threads->tid(); }
