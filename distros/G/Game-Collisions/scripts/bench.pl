#!perl
# Copyright (c) 2018  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
use v5.14;
use warnings;
use Time::HiRes qw( gettimeofday tv_interval );
use Game::Collisions;

use constant FPS => 60;
use constant ITERATION_COUNT => FPS * 100;

my @OBJECT_DEFINITIONS = (
    {
      'height' => 1,
      'y' => 40,
      'length' => 9,
      'x' => 92
    },
    {
      'height' => 0,
      'length' => 6,
      'y' => 92,
      'x' => 44
    },
    {
      'x' => 78,
      'length' => 9,
      'y' => 13,
      'height' => 1
    },
    {
      'y' => 21,
      'length' => 6,
      'x' => 88,
      'height' => 9
    },
    {
      'y' => 49,
      'length' => 2,
      'x' => 53,
      'height' => 9
    },
    {
      'x' => 15,
      'length' => 2,
      'y' => 56,
      'height' => 2
    },
    {
      'y' => 22,
      'length' => 5,
      'x' => 53,
      'height' => 2
    },
    {
      'x' => 22,
      'length' => 5,
      'y' => 17,
      'height' => 0
    },
    {
      'length' => 6,
      'y' => 11,
      'x' => 63,
      'height' => 0
    },
    {
      'height' => 8,
      'x' => 95,
      'length' => 1,
      'y' => 89
    },
    {
      'length' => 7,
      'x' => 22,
      'y' => 18,
      'height' => 9
    },
    {
      'height' => 4,
      'x' => 32,
      'length' => 1,
      'y' => 9
    },
    {
      'y' => 89,
      'length' => 8,
      'x' => 43,
      'height' => 0
    },
    {
      'height' => 0,
      'x' => 88,
      'length' => 9,
      'y' => 38
    },
    {
      'height' => 6,
      'y' => 50,
      'length' => 0,
      'x' => 47
    },
    {
      'height' => 2,
      'x' => 56,
      'length' => 9,
      'y' => 77
    },
    {
      'y' => 21,
      'length' => 4,
      'x' => 23,
      'height' => 3
    },
    {
      'y' => 35,
      'length' => 2,
      'x' => 23,
      'height' => 0
    },
    {
      'length' => 0,
      'y' => 70,
      'x' => 85,
      'height' => 5
    },
    {
      'height' => 6,
      'x' => 27,
      'length' => 3,
      'y' => 60
    },
    {
      'length' => 6,
      'y' => 33,
      'x' => 31,
      'height' => 7
    },
    {
      'length' => 3,
      'y' => 91,
      'x' => 49,
      'height' => 9
    },
    {
      'height' => 4,
      'y' => 28,
      'length' => 6,
      'x' => 94
    },
    {
      'height' => 7,
      'length' => 2,
      'x' => 46,
      'y' => 5
    },
    {
      'y' => 38,
      'length' => 3,
      'x' => 91,
      'height' => 5
    },
    {
      'height' => 4,
      'length' => 6,
      'x' => 88,
      'y' => 13
    },
    {
      'height' => 6,
      'length' => 7,
      'x' => 12,
      'y' => 4
    },
    {
      'height' => 1,
      'length' => 7,
      'y' => 16,
      'x' => 67
    },
    {
      'x' => 20,
      'length' => 4,
      'y' => 36,
      'height' => 7
    },
    {
      'length' => 8,
      'x' => 51,
      'y' => 8,
      'height' => 6
    },
    {
      'height' => 9,
      'y' => 18,
      'length' => 0,
      'x' => 20
    },
    {
      'height' => 7,
      'y' => 85,
      'length' => 6,
      'x' => 33
    },
    {
      'height' => 2,
      'y' => 67,
      'length' => 5,
      'x' => 95
    },
    {
      'height' => 5,
      'length' => 1,
      'y' => 72,
      'x' => 48
    },
    {
      'x' => 65,
      'length' => 5,
      'y' => 61,
      'height' => 7
    },
    {
      'y' => 18,
      'length' => 1,
      'x' => 56,
      'height' => 0
    },
    {
      'y' => 70,
      'length' => 7,
      'x' => 28,
      'height' => 8
    },
    {
      'x' => 16,
      'length' => 5,
      'y' => 86,
      'height' => 8
    },
    {
      'y' => 37,
      'length' => 8,
      'x' => 2,
      'height' => 1
    },
    {
      'height' => 2,
      'x' => 56,
      'length' => 2,
      'y' => 92
    },
    {
      'height' => 2,
      'length' => 5,
      'y' => 53,
      'x' => 71
    },
    {
      'height' => 1,
      'x' => 75,
      'length' => 6,
      'y' => 67
    },
    {
      'length' => 3,
      'x' => 76,
      'y' => 8,
      'height' => 6
    },
    {
      'height' => 7,
      'x' => 87,
      'length' => 0,
      'y' => 92
    },
    {
      'y' => 76,
      'length' => 5,
      'x' => 40,
      'height' => 1
    },
    {
      'height' => 3,
      'x' => 73,
      'length' => 7,
      'y' => 47
    },
    {
      'y' => 77,
      'length' => 7,
      'x' => 62,
      'height' => 3
    },
    {
      'height' => 4,
      'x' => 25,
      'length' => 5,
      'y' => 31
    },
    {
      'y' => 93,
      'length' => 2,
      'x' => 30,
      'height' => 1
    },
    {
      'y' => 78,
      'length' => 8,
      'x' => 74,
      'height' => 9
    },
    {
      'height' => 2,
      'length' => 2,
      'y' => 61,
      'x' => 34
    },
    {
      'height' => 8,
      'x' => 86,
      'length' => 5,
      'y' => 44
    },
    {
      'height' => 2,
      'length' => 1,
      'y' => 31,
      'x' => 57
    },
    {
      'length' => 4,
      'y' => 80,
      'x' => 22,
      'height' => 0
    },
    {
      'height' => 2,
      'y' => 36,
      'length' => 0,
      'x' => 19
    },
    {
      'height' => 2,
      'length' => 6,
      'x' => 4,
      'y' => 4
    },
    {
      'y' => 72,
      'length' => 6,
      'x' => 55,
      'height' => 4
    },
    {
      'height' => 5,
      'length' => 0,
      'x' => 57,
      'y' => 86
    },
    {
      'height' => 9,
      'length' => 5,
      'x' => 71,
      'y' => 50
    },
    {
      'length' => 4,
      'y' => 13,
      'x' => 86,
      'height' => 8
    },
    {
      'height' => 1,
      'x' => 4,
      'length' => 9,
      'y' => 79
    },
    {
      'length' => 7,
      'x' => 86,
      'y' => 53,
      'height' => 0
    },
    {
      'height' => 1,
      'y' => 39,
      'length' => 3,
      'x' => 60
    },
    {
      'y' => 57,
      'length' => 0,
      'x' => 30,
      'height' => 6
    },
    {
      'height' => 6,
      'y' => 92,
      'length' => 0,
      'x' => 77
    },
    {
      'length' => 4,
      'y' => 36,
      'x' => 30,
      'height' => 3
    },
    {
      'x' => 76,
      'length' => 5,
      'y' => 96,
      'height' => 1
    },
    {
      'height' => 0,
      'y' => 30,
      'length' => 2,
      'x' => 62
    },
    {
      'y' => 66,
      'length' => 6,
      'x' => 32,
      'height' => 7
    },
    {
      'height' => 4,
      'x' => 94,
      'length' => 1,
      'y' => 46
    },
    {
      'y' => 74,
      'length' => 5,
      'x' => 72,
      'height' => 4
    },
    {
      'x' => 34,
      'length' => 8,
      'y' => 65,
      'height' => 1
    },
    {
      'height' => 4,
      'length' => 5,
      'y' => 38,
      'x' => 74
    },
    {
      'x' => 39,
      'length' => 8,
      'y' => 46,
      'height' => 8
    },
    {
      'length' => 1,
      'x' => 10,
      'y' => 27,
      'height' => 1
    },
    {
      'x' => 93,
      'length' => 2,
      'y' => 33,
      'height' => 6
    },
    {
      'y' => 47,
      'length' => 0,
      'x' => 81,
      'height' => 2
    },
    {
      'height' => 8,
      'x' => 48,
      'length' => 9,
      'y' => 48
    },
    {
      'height' => 2,
      'y' => 9,
      'length' => 3,
      'x' => 88
    },
    {
      'x' => 2,
      'length' => 4,
      'y' => 91,
      'height' => 4
    },
    {
      'y' => 35,
      'length' => 7,
      'x' => 51,
      'height' => 6
    },
    {
      'y' => 11,
      'length' => 2,
      'x' => 18,
      'height' => 2
    },
    {
      'height' => 0,
      'length' => 3,
      'y' => 2,
      'x' => 49
    },
    {
      'x' => 89,
      'length' => 3,
      'y' => 89,
      'height' => 6
    },
    {
      'height' => 7,
      'length' => 9,
      'y' => 7,
      'x' => 36
    },
    {
      'length' => 3,
      'y' => 74,
      'x' => 21,
      'height' => 0
    },
    {
      'height' => 2,
      'y' => 30,
      'length' => 4,
      'x' => 4
    },
    {
      'height' => 1,
      'length' => 0,
      'x' => 36,
      'y' => 79
    },
    {
      'height' => 7,
      'y' => 36,
      'length' => 4,
      'x' => 43
    },
    {
      'height' => 1,
      'length' => 7,
      'x' => 5,
      'y' => 49
    },
    {
      'length' => 4,
      'x' => 27,
      'y' => 82,
      'height' => 9
    },
    {
      'height' => 8,
      'length' => 6,
      'y' => 71,
      'x' => 48
    },
    {
      'x' => 41,
      'length' => 8,
      'y' => 32,
      'height' => 1
    },
    {
      'height' => 0,
      'length' => 5,
      'x' => 44,
      'y' => 62
    },
    {
      'y' => 59,
      'length' => 6,
      'x' => 0,
      'height' => 1
    },
    {
      'height' => 6,
      'y' => 35,
      'length' => 9,
      'x' => 61
    },
    {
      'y' => 6,
      'length' => 6,
      'x' => 95,
      'height' => 4
    },
    {
      'length' => 7,
      'y' => 42,
      'x' => 53,
      'height' => 5
    },
    {
      'x' => 11,
      'length' => 0,
      'y' => 4,
      'height' => 3
    },
    {
      'height' => 2,
      'y' => 48,
      'length' => 6,
      'x' => 75
    },
    {
      'y' => 11,
      'length' => 0,
      'x' => 13,
      'height' => 2
    },
    {
      'height' => 9,
      'x' => 17,
      'length' => 0,
      'y' => 67
    },
    {
      'height' => 8,
      'y' => 96,
      'length' => 5,
      'x' => 36
    },
    {
      'x' => 25,
      'length' => 6,
      'y' => 29,
      'height' => 1
    },
    {
      'length' => 0,
      'y' => 37,
      'x' => 78,
      'height' => 1
    },
    {
      'x' => 13,
      'length' => 4,
      'y' => 25,
      'height' => 6
    },
    {
      'height' => 3,
      'length' => 8,
      'x' => 67,
      'y' => 3
    },
    {
      'x' => 25,
      'length' => 1,
      'y' => 20,
      'height' => 7
    },
    {
      'y' => 86,
      'length' => 2,
      'x' => 8,
      'height' => 5
    },
    {
      'x' => 14,
      'length' => 7,
      'y' => 51,
      'height' => 0
    },
    {
      'y' => 33,
      'length' => 1,
      'x' => 53,
      'height' => 1
    },
    {
      'height' => 1,
      'x' => 45,
      'length' => 1,
      'y' => 88
    },
    {
      'height' => 6,
      'y' => 56,
      'length' => 4,
      'x' => 65
    },
    {
      'height' => 9,
      'y' => 61,
      'length' => 9,
      'x' => 14
    },
    {
      'length' => 2,
      'y' => 32,
      'x' => 70,
      'height' => 3
    },
    {
      'x' => 13,
      'length' => 1,
      'y' => 74,
      'height' => 0
    },
    {
      'height' => 8,
      'length' => 2,
      'y' => 21,
      'x' => 89
    },
    {
      'length' => 5,
      'y' => 69,
      'x' => 9,
      'height' => 6
    },
    {
      'y' => 99,
      'length' => 2,
      'x' => 47,
      'height' => 0
    },
    {
      'length' => 7,
      'x' => 48,
      'y' => 12,
      'height' => 3
    },
    {
      'y' => 68,
      'length' => 0,
      'x' => 52,
      'height' => 8
    },
    {
      'length' => 3,
      'x' => 11,
      'y' => 69,
      'height' => 4
    },
    {
      'height' => 8,
      'length' => 0,
      'x' => 99,
      'y' => 41
    },
    {
      'height' => 2,
      'length' => 9,
      'y' => 83,
      'x' => 56
    },
    {
      'height' => 0,
      'x' => 45,
      'length' => 6,
      'y' => 36
    },
    {
      'height' => 0,
      'length' => 0,
      'x' => 99,
      'y' => 36
    },
    {
      'y' => 75,
      'length' => 6,
      'x' => 52,
      'height' => 3
    },
    {
      'height' => 1,
      'y' => 82,
      'length' => 3,
      'x' => 65
    },
    {
      'y' => 85,
      'length' => 5,
      'x' => 43,
      'height' => 3
    },
    {
      'height' => 6,
      'length' => 5,
      'y' => 40,
      'x' => 31
    },
    {
      'x' => 69,
      'length' => 5,
      'y' => 47,
      'height' => 4
    },
    {
      'height' => 6,
      'y' => 21,
      'length' => 1,
      'x' => 70
    },
    {
      'y' => 51,
      'length' => 9,
      'x' => 14,
      'height' => 3
    },
    {
      'x' => 50,
      'length' => 6,
      'y' => 14,
      'height' => 5
    },
    {
      'height' => 1,
      'y' => 38,
      'length' => 5,
      'x' => 88
    },
    {
      'height' => 9,
      'x' => 9,
      'length' => 8,
      'y' => 89
    },
    {
      'height' => 0,
      'length' => 7,
      'y' => 1,
      'x' => 68
    },
    {
      'height' => 8,
      'x' => 86,
      'length' => 2,
      'y' => 99
    },
    {
      'length' => 8,
      'x' => 60,
      'y' => 60,
      'height' => 7
    },
    {
      'x' => 0,
      'length' => 3,
      'y' => 32,
      'height' => 8
    },
    {
      'height' => 6,
      'y' => 87,
      'length' => 4,
      'x' => 57
    },
    {
      'x' => 26,
      'length' => 9,
      'y' => 61,
      'height' => 8
    },
    {
      'height' => 0,
      'y' => 78,
      'length' => 4,
      'x' => 26
    },
    {
      'height' => 7,
      'x' => 8,
      'length' => 2,
      'y' => 51
    },
    {
      'height' => 5,
      'y' => 44,
      'length' => 9,
      'x' => 76
    },
    {
      'height' => 2,
      'y' => 60,
      'length' => 2,
      'x' => 90
    },
    {
      'length' => 0,
      'y' => 6,
      'x' => 80,
      'height' => 8
    },
    {
      'height' => 7,
      'x' => 15,
      'length' => 5,
      'y' => 3
    },
    {
      'height' => 8,
      'length' => 7,
      'y' => 97,
      'x' => 31
    },
    {
      'length' => 3,
      'y' => 5,
      'x' => 60,
      'height' => 2
    },
    {
      'height' => 3,
      'y' => 46,
      'length' => 7,
      'x' => 14
    },
    {
      'height' => 0,
      'length' => 3,
      'x' => 27,
      'y' => 64
    },
    {
      'y' => 76,
      'length' => 2,
      'x' => 57,
      'height' => 8
    },
    {
      'height' => 2,
      'length' => 3,
      'x' => 33,
      'y' => 31
    },
    {
      'height' => 3,
      'length' => 7,
      'x' => 19,
      'y' => 3
    },
    {
      'length' => 2,
      'y' => 97,
      'x' => 25,
      'height' => 3
    },
    {
      'x' => 21,
      'length' => 3,
      'y' => 40,
      'height' => 9
    },
    {
      'height' => 6,
      'length' => 9,
      'x' => 99,
      'y' => 85
    },
    {
      'y' => 66,
      'length' => 0,
      'x' => 20,
      'height' => 6
    },
    {
      'y' => 23,
      'length' => 9,
      'x' => 45,
      'height' => 2
    },
    {
      'y' => 70,
      'length' => 5,
      'x' => 37,
      'height' => 3
    },
    {
      'length' => 2,
      'y' => 3,
      'x' => 67,
      'height' => 3
    },
    {
      'x' => 40,
      'length' => 2,
      'y' => 40,
      'height' => 5
    },
    {
      'height' => 8,
      'y' => 90,
      'length' => 3,
      'x' => 68
    },
    {
      'height' => 0,
      'y' => 79,
      'length' => 1,
      'x' => 67
    },
    {
      'height' => 8,
      'x' => 87,
      'length' => 6,
      'y' => 12
    },
    {
      'height' => 7,
      'y' => 86,
      'length' => 1,
      'x' => 39
    },
    {
      'x' => 16,
      'length' => 4,
      'y' => 90,
      'height' => 1
    },
    {
      'height' => 0,
      'length' => 9,
      'y' => 39,
      'x' => 4
    },
    {
      'x' => 48,
      'length' => 3,
      'y' => 94,
      'height' => 7
    },
    {
      'length' => 8,
      'x' => 66,
      'y' => 95,
      'height' => 4
    },
    {
      'x' => 18,
      'length' => 3,
      'y' => 70,
      'height' => 8
    },
    {
      'height' => 2,
      'y' => 44,
      'length' => 3,
      'x' => 46
    },
    {
      'x' => 33,
      'length' => 9,
      'y' => 97,
      'height' => 1
    },
    {
      'height' => 0,
      'y' => 93,
      'length' => 5,
      'x' => 17
    },
    {
      'height' => 9,
      'x' => 82,
      'length' => 6,
      'y' => 33
    },
    {
      'y' => 39,
      'length' => 7,
      'x' => 11,
      'height' => 5
    },
    {
      'height' => 1,
      'y' => 76,
      'length' => 2,
      'x' => 85
    },
    {
      'length' => 0,
      'y' => 68,
      'x' => 98,
      'height' => 3
    },
    {
      'height' => 7,
      'x' => 68,
      'length' => 5,
      'y' => 33
    },
    {
      'length' => 2,
      'y' => 97,
      'x' => 56,
      'height' => 3
    },
    {
      'length' => 2,
      'y' => 0,
      'x' => 1,
      'height' => 9
    },
    {
      'height' => 5,
      'y' => 61,
      'length' => 7,
      'x' => 29
    },
    {
      'height' => 0,
      'length' => 3,
      'x' => 84,
      'y' => 98
    },
    {
      'y' => 16,
      'length' => 3,
      'x' => 99,
      'height' => 8
    },
    {
      'height' => 7,
      'length' => 3,
      'x' => 51,
      'y' => 58
    },
    {
      'length' => 1,
      'x' => 30,
      'y' => 56,
      'height' => 0
    },
    {
      'length' => 6,
      'y' => 46,
      'x' => 23,
      'height' => 3
    },
    {
      'height' => 3,
      'x' => 51,
      'length' => 3,
      'y' => 72
    },
    {
      'height' => 5,
      'length' => 4,
      'x' => 2,
      'y' => 50
    },
    {
      'height' => 3,
      'y' => 72,
      'length' => 7,
      'x' => 88
    },
    {
      'y' => 69,
      'length' => 9,
      'x' => 15,
      'height' => 4
    },
    {
      'height' => 9,
      'y' => 46,
      'length' => 2,
      'x' => 9
    },
    {
      'height' => 0,
      'length' => 8,
      'y' => 52,
      'x' => 97
    },
    {
      'height' => 2,
      'x' => 96,
      'length' => 5,
      'y' => 28
    },
    {
      'y' => 10,
      'length' => 2,
      'x' => 77,
      'height' => 9
    },
    {
      'y' => 19,
      'length' => 4,
      'x' => 79,
      'height' => 4
    },
    {
      'height' => 2,
      'x' => 1,
      'length' => 4,
      'y' => 79
    },
    {
      'height' => 2,
      'y' => 57,
      'length' => 5,
      'x' => 2
    },
    {
      'x' => 69,
      'length' => 5,
      'y' => 50,
      'height' => 2
    },
    {
      'length' => 5,
      'y' => 0,
      'x' => 9,
      'height' => 0
    },
    {
      'x' => 29,
      'length' => 2,
      'y' => 92,
      'height' => 2
    },
    {
      'length' => 6,
      'x' => 16,
      'y' => 56,
      'height' => 4
    },
    {
      'x' => 0,
      'length' => 6,
      'y' => 81,
      'height' => 1
    },
    {
      'height' => 2,
      'y' => 18,
      'length' => 0,
      'x' => 71
    },
    {
      'height' => 5,
      'x' => 18,
      'length' => 5,
      'y' => 28
    },
    {
      'y' => 25,
      'length' => 2,
      'x' => 60,
      'height' => 8
    },
    {
      'height' => 9,
      'x' => 35,
      'length' => 5,
      'y' => 37
    },
    {
      'height' => 1,
      'y' => 12,
      'length' => 8,
      'x' => 6
    },
    {
      'y' => 41,
      'length' => 3,
      'x' => 92,
      'height' => 1
    },
    {
      'length' => 0,
      'y' => 37,
      'x' => 70,
      'height' => 8
    },
    {
      'x' => 1,
      'length' => 6,
      'y' => 0,
      'height' => 3
    },
    {
      'height' => 6,
      'length' => 7,
      'y' => 97,
      'x' => 32
    },
    {
      'length' => 0,
      'y' => 77,
      'x' => 58,
      'height' => 5
    },
    {
      'height' => 8,
      'y' => 5,
      'length' => 6,
      'x' => 68
    },
    {
      'length' => 1,
      'x' => 90,
      'y' => 16,
      'height' => 0
    },
    {
      'height' => 0,
      'y' => 73,
      'length' => 3,
      'x' => 80
    },
    {
      'length' => 0,
      'x' => 8,
      'y' => 46,
      'height' => 7
    },
    {
      'height' => 2,
      'length' => 0,
      'x' => 72,
      'y' => 78
    },
    {
      'height' => 4,
      'length' => 9,
      'y' => 76,
      'x' => 10
    },
    {
      'x' => 88,
      'length' => 7,
      'y' => 23,
      'height' => 9
    },
    {
      'length' => 0,
      'x' => 26,
      'y' => 34,
      'height' => 6
    },
    {
      'y' => 67,
      'length' => 7,
      'x' => 14,
      'height' => 7
    },
    {
      'height' => 4,
      'y' => 49,
      'length' => 6,
      'x' => 34
    },
    {
      'y' => 16,
      'length' => 5,
      'x' => 99,
      'height' => 1
    },
    {
      'height' => 2,
      'length' => 2,
      'y' => 84,
      'x' => 29
    },
    {
      'height' => 0,
      'x' => 78,
      'length' => 5,
      'y' => 71
    },
    {
      'y' => 80,
      'length' => 1,
      'x' => 35,
      'height' => 0
    },
    {
      'height' => 7,
      'y' => 98,
      'length' => 6,
      'x' => 24
    },
    {
      'height' => 9,
      'x' => 77,
      'length' => 5,
      'y' => 48
    },
    {
      'y' => 74,
      'length' => 4,
      'x' => 85,
      'height' => 4
    },
    {
      'x' => 25,
      'length' => 3,
      'y' => 83,
      'height' => 6
    },
    {
      'length' => 3,
      'y' => 46,
      'x' => 59,
      'height' => 7
    },
    {
      'x' => 44,
      'length' => 0,
      'y' => 58,
      'height' => 0
    },
    {
      'length' => 4,
      'x' => 82,
      'y' => 21,
      'height' => 1
    },
    {
      'x' => 30,
      'length' => 0,
      'y' => 91,
      'height' => 2
    },
    {
      'y' => 23,
      'length' => 5,
      'x' => 89,
      'height' => 9
    },
    {
      'x' => 39,
      'length' => 5,
      'y' => 99,
      'height' => 6
    },
    {
      'y' => 0,
      'length' => 0,
      'x' => 8,
      'height' => 4
    },
    {
      'height' => 2,
      'x' => 54,
      'length' => 1,
      'y' => 47
    },
    {
      'y' => 47,
      'length' => 1,
      'x' => 0,
      'height' => 8
    },
    {
      'y' => 76,
      'length' => 0,
      'x' => 95,
      'height' => 7
    },
    {
      'length' => 5,
      'y' => 78,
      'x' => 55,
      'height' => 7
    },
    {
      'height' => 2,
      'x' => 42,
      'length' => 3,
      'y' => 49
    },
    {
      'height' => 3,
      'length' => 1,
      'y' => 70,
      'x' => 89
    },
    {
      'height' => 6,
      'length' => 1,
      'y' => 91,
      'x' => 87
    },
    {
      'y' => 83,
      'length' => 2,
      'x' => 46,
      'height' => 2
    },
    {
      'length' => 1,
      'x' => 21,
      'y' => 79,
      'height' => 9
    },
    {
      'height' => 1,
      'y' => 32,
      'length' => 1,
      'x' => 48
    },
    {
      'height' => 4,
      'length' => 0,
      'x' => 49,
      'y' => 87
    },
    {
      'length' => 7,
      'x' => 76,
      'y' => 16,
      'height' => 7
    },
    {
      'height' => 9,
      'length' => 4,
      'y' => 74,
      'x' => 81
    },
    {
      'height' => 7,
      'x' => 44,
      'length' => 1,
      'y' => 23
    },
    {
      'length' => 3,
      'x' => 82,
      'y' => 27,
      'height' => 5
    },
    {
      'y' => 45,
      'length' => 6,
      'x' => 19,
      'height' => 0
    },
    {
      'height' => 2,
      'y' => 36,
      'length' => 9,
      'x' => 51
    },
    {
      'height' => 4,
      'y' => 85,
      'length' => 8,
      'x' => 42
    },
    {
      'height' => 1,
      'length' => 6,
      'y' => 4,
      'x' => 84
    },
    {
      'height' => 8,
      'x' => 90,
      'length' => 7,
      'y' => 12
    },
    {
      'y' => 74,
      'length' => 0,
      'x' => 47,
      'height' => 5
    },
    {
      'y' => 27,
      'length' => 2,
      'x' => 36,
      'height' => 7
    },
    {
      'height' => 4,
      'x' => 55,
      'length' => 9,
      'y' => 2
    },
    {
      'height' => 6,
      'y' => 44,
      'length' => 5,
      'x' => 83
    },
    {
      'height' => 5,
      'x' => 15,
      'length' => 7,
      'y' => 30
    },
    {
      'height' => 4,
      'length' => 9,
      'y' => 34,
      'x' => 75
    },
    {
      'height' => 7,
      'x' => 30,
      'length' => 7,
      'y' => 69
    },
    {
      'height' => 0,
      'length' => 7,
      'x' => 73,
      'y' => 76
    },
    {
      'x' => 96,
      'length' => 1,
      'y' => 29,
      'height' => 0
    },
    {
      'height' => 7,
      'y' => 99,
      'length' => 4,
      'x' => 15
    },
    {
      'x' => 70,
      'length' => 6,
      'y' => 55,
      'height' => 7
    },
    {
      'height' => 0,
      'y' => 96,
      'length' => 9,
      'x' => 22
    },
    {
      'height' => 1,
      'x' => 86,
      'length' => 1,
      'y' => 56
    },
    {
      'y' => 12,
      'length' => 5,
      'x' => 23,
      'height' => 9
    },
    {
      'height' => 7,
      'y' => 22,
      'length' => 5,
      'x' => 11
    },
    {
      'length' => 9,
      'y' => 86,
      'x' => 24,
      'height' => 5
    },
    {
      'x' => 61,
      'length' => 5,
      'y' => 64,
      'height' => 9
    },
    {
      'height' => 7,
      'length' => 0,
      'y' => 61,
      'x' => 11
    },
    {
      'length' => 3,
      'y' => 54,
      'x' => 23,
      'height' => 5
    },
    {
      'height' => 1,
      'y' => 26,
      'length' => 4,
      'x' => 8
    },
    {
      'length' => 0,
      'x' => 96,
      'y' => 39,
      'height' => 5
    },
    {
      'y' => 64,
      'length' => 8,
      'x' => 95,
      'height' => 1
    },
    {
      'height' => 0,
      'length' => 1,
      'x' => 63,
      'y' => 1
    },
    {
      'length' => 0,
      'x' => 49,
      'y' => 65,
      'height' => 3
    },
    {
      'length' => 0,
      'y' => 94,
      'x' => 2,
      'height' => 2
    },
    {
      'x' => 85,
      'length' => 4,
      'y' => 20,
      'height' => 9
    },
    {
      'height' => 7,
      'length' => 0,
      'x' => 15,
      'y' => 40
    },
    {
      'y' => 93,
      'length' => 6,
      'x' => 78,
      'height' => 2
    },
    {
      'height' => 0,
      'y' => 73,
      'length' => 1,
      'x' => 43
    },
    {
      'y' => 34,
      'length' => 1,
      'x' => 61,
      'height' => 1
    },
    {
      'length' => 2,
      'y' => 46,
      'x' => 38,
      'height' => 2
    },
    {
      'x' => 87,
      'length' => 1,
      'y' => 63,
      'height' => 0
    },
    {
      'height' => 9,
      'y' => 66,
      'length' => 3,
      'x' => 28
    },
    {
      'y' => 79,
      'length' => 8,
      'x' => 96,
      'height' => 8
    },
    {
      'height' => 1,
      'x' => 73,
      'length' => 1,
      'y' => 95
    },
    {
      'y' => 41,
      'length' => 7,
      'x' => 67,
      'height' => 6
    },
    {
      'x' => 82,
      'length' => 7,
      'y' => 87,
      'height' => 1
    },
    {
      'height' => 4,
      'length' => 1,
      'y' => 90,
      'x' => 13
    },
    {
      'x' => 86,
      'length' => 1,
      'y' => 45,
      'height' => 6
    },
    {
      'height' => 3,
      'length' => 1,
      'x' => 23,
      'y' => 93
    },
    {
      'height' => 8,
      'x' => 31,
      'length' => 6,
      'y' => 58
    },
    {
      'y' => 96,
      'length' => 6,
      'x' => 12,
      'height' => 5
    },
    {
      'height' => 3,
      'x' => 42,
      'length' => 7,
      'y' => 76
    },
    {
      'y' => 27,
      'length' => 5,
      'x' => 63,
      'height' => 5
    },
    {
      'x' => 73,
      'length' => 3,
      'y' => 93,
      'height' => 2
    },
    {
      'height' => 0,
      'y' => 43,
      'length' => 0,
      'x' => 89
    },
    {
      'height' => 0,
      'y' => 70,
      'length' => 1,
      'x' => 33
    },
    {
      'length' => 3,
      'y' => 59,
      'x' => 43,
      'height' => 1
    },
    {
      'height' => 0,
      'x' => 2,
      'length' => 7,
      'y' => 90
    },
    {
      'height' => 5,
      'length' => 4,
      'y' => 65,
      'x' => 24
    },
    {
      'height' => 3,
      'length' => 4,
      'y' => 72,
      'x' => 16
    },
    {
      'y' => 67,
      'length' => 0,
      'x' => 24,
      'height' => 9
    },
    {
      'length' => 6,
      'x' => 21,
      'y' => 66,
      'height' => 3
    },
    {
      'y' => 99,
      'length' => 5,
      'x' => 38,
      'height' => 3
    },
    {
      'height' => 8,
      'length' => 9,
      'x' => 21,
      'y' => 62
    },
    {
      'length' => 5,
      'x' => 74,
      'y' => 42,
      'height' => 7
    },
    {
      'length' => 9,
      'y' => 89,
      'x' => 57,
      'height' => 9
    },
    {
      'height' => 3,
      'x' => 15,
      'length' => 4,
      'y' => 56
    },
    {
      'height' => 2,
      'length' => 5,
      'x' => 49,
      'y' => 27
    },
    {
      'y' => 68,
      'length' => 5,
      'x' => 9,
      'height' => 2
    },
    {
      'y' => 5,
      'length' => 5,
      'x' => 58,
      'height' => 4
    },
    {
      'y' => 97,
      'length' => 9,
      'x' => 58,
      'height' => 7
    },
    {
      'length' => 0,
      'y' => 11,
      'x' => 57,
      'height' => 6
    },
    {
      'x' => 70,
      'length' => 0,
      'y' => 80,
      'height' => 0
    },
    {
      'height' => 2,
      'y' => 57,
      'length' => 7,
      'x' => 42
    },
    {
      'y' => 68,
      'length' => 9,
      'x' => 26,
      'height' => 0
    },
    {
      'height' => 5,
      'x' => 5,
      'length' => 8,
      'y' => 85
    },
    {
      'height' => 6,
      'y' => 79,
      'length' => 0,
      'x' => 73
    },
    {
      'height' => 4,
      'x' => 25,
      'length' => 4,
      'y' => 30
    },
    {
      'height' => 7,
      'length' => 1,
      'y' => 93,
      'x' => 54
    },
    {
      'height' => 2,
      'x' => 18,
      'length' => 0,
      'y' => 71
    },
    {
      'height' => 8,
      'length' => 5,
      'x' => 81,
      'y' => 7
    },
    {
      'x' => 54,
      'length' => 5,
      'y' => 1,
      'height' => 3
    },
    {
      'y' => 45,
      'length' => 0,
      'x' => 77,
      'height' => 5
    },
    {
      'x' => 80,
      'length' => 8,
      'y' => 98,
      'height' => 7
    },
    {
      'height' => 0,
      'y' => 17,
      'length' => 3,
      'x' => 79
    },
    {
      'height' => 9,
      'x' => 2,
      'length' => 4,
      'y' => 50
    },
    {
      'y' => 22,
      'length' => 1,
      'x' => 84,
      'height' => 7
    },
    {
      'height' => 1,
      'y' => 82,
      'length' => 3,
      'x' => 66
    },
    {
      'height' => 5,
      'length' => 2,
      'y' => 80,
      'x' => 65
    },
    {
      'height' => 9,
      'x' => 34,
      'length' => 9,
      'y' => 68
    },
    {
      'height' => 3,
      'length' => 1,
      'y' => 9,
      'x' => 93
    },
    {
      'height' => 0,
      'length' => 0,
      'y' => 62,
      'x' => 74
    },
    {
      'y' => 21,
      'length' => 8,
      'x' => 71,
      'height' => 0
    },
    {
      'height' => 4,
      'length' => 6,
      'x' => 24,
      'y' => 77
    },
    {
      'y' => 6,
      'length' => 7,
      'x' => 21,
      'height' => 2
    },
    {
      'length' => 0,
      'x' => 23,
      'y' => 27,
      'height' => 1
    },
    {
      'length' => 7,
      'x' => 90,
      'y' => 70,
      'height' => 1
    },
    {
      'height' => 6,
      'length' => 1,
      'y' => 35,
      'x' => 83
    },
    {
      'x' => 74,
      'length' => 2,
      'y' => 48,
      'height' => 8
    },
    {
      'height' => 6,
      'length' => 5,
      'x' => 26,
      'y' => 16
    },
    {
      'height' => 2,
      'y' => 80,
      'length' => 3,
      'x' => 64
    },
    {
      'height' => 3,
      'y' => 7,
      'length' => 1,
      'x' => 53
    },
    {
      'height' => 6,
      'y' => 45,
      'length' => 2,
      'x' => 2
    },
    {
      'height' => 0,
      'length' => 1,
      'y' => 85,
      'x' => 47
    },
    {
      'height' => 6,
      'x' => 70,
      'length' => 5,
      'y' => 43
    },
    {
      'height' => 2,
      'y' => 7,
      'length' => 5,
      'x' => 43
    },
    {
      'y' => 24,
      'length' => 6,
      'x' => 76,
      'height' => 1
    },
    {
      'x' => 2,
      'length' => 0,
      'y' => 61,
      'height' => 2
    },
    {
      'height' => 1,
      'y' => 91,
      'length' => 5,
      'x' => 97
    },
    {
      'x' => 40,
      'length' => 5,
      'y' => 48,
      'height' => 6
    },
    {
      'height' => 3,
      'length' => 4,
      'y' => 48,
      'x' => 97
    },
    {
      'height' => 7,
      'x' => 76,
      'length' => 6,
      'y' => 32
    },
    {
      'length' => 1,
      'x' => 2,
      'y' => 96,
      'height' => 4
    },
    {
      'x' => 6,
      'length' => 2,
      'y' => 71,
      'height' => 6
    },
    {
      'height' => 3,
      'y' => 40,
      'length' => 9,
      'x' => 36
    },
    {
      'x' => 51,
      'length' => 6,
      'y' => 49,
      'height' => 2
    },
    {
      'y' => 78,
      'length' => 9,
      'x' => 2,
      'height' => 3
    },
    {
      'height' => 0,
      'x' => 38,
      'length' => 7,
      'y' => 14
    },
    {
      'y' => 50,
      'length' => 5,
      'x' => 58,
      'height' => 8
    },
    {
      'y' => 29,
      'length' => 3,
      'x' => 72,
      'height' => 4
    },
    {
      'length' => 1,
      'y' => 93,
      'x' => 26,
      'height' => 5
    },
    {
      'height' => 3,
      'x' => 84,
      'length' => 2,
      'y' => 59
    },
    {
      'length' => 8,
      'y' => 22,
      'x' => 3,
      'height' => 1
    },
    {
      'length' => 1,
      'y' => 91,
      'x' => 2,
      'height' => 5
    },
    {
      'y' => 59,
      'length' => 9,
      'x' => 35,
      'height' => 8
    },
    {
      'height' => 7,
      'length' => 1,
      'x' => 0,
      'y' => 63
    },
    {
      'height' => 9,
      'y' => 71,
      'length' => 6,
      'x' => 94
    },
    {
      'length' => 0,
      'x' => 29,
      'y' => 63,
      'height' => 8
    },
    {
      'length' => 3,
      'x' => 90,
      'y' => 52,
      'height' => 9
    },
    {
      'length' => 1,
      'y' => 62,
      'x' => 14,
      'height' => 3
    },
    {
      'height' => 9,
      'x' => 22,
      'length' => 3,
      'y' => 62
    },
    {
      'height' => 5,
      'length' => 8,
      'x' => 43,
      'y' => 38
    },
    {
      'y' => 67,
      'length' => 9,
      'x' => 25,
      'height' => 9
    },
    {
      'height' => 1,
      'y' => 8,
      'length' => 4,
      'x' => 37
    },
    {
      'y' => 58,
      'length' => 2,
      'x' => 22,
      'height' => 8
    },
    {
      'length' => 6,
      'y' => 75,
      'x' => 85,
      'height' => 5
    },
    {
      'x' => 46,
      'length' => 6,
      'y' => 29,
      'height' => 1
    },
    {
      'y' => 60,
      'length' => 4,
      'x' => 19,
      'height' => 7
    },
    {
      'y' => 75,
      'length' => 0,
      'x' => 19,
      'height' => 2
    },
    {
      'height' => 0,
      'x' => 34,
      'length' => 3,
      'y' => 70
    },
    {
      'y' => 8,
      'length' => 6,
      'x' => 83,
      'height' => 4
    },
    {
      'height' => 8,
      'x' => 58,
      'length' => 7,
      'y' => 68
    },
    {
      'height' => 1,
      'length' => 0,
      'y' => 66,
      'x' => 46
    },
    {
      'height' => 3,
      'x' => 94,
      'length' => 5,
      'y' => 35
    },
    {
      'length' => 3,
      'x' => 38,
      'y' => 57,
      'height' => 8
    },
    {
      'height' => 2,
      'x' => 97,
      'length' => 7,
      'y' => 97
    },
    {
      'height' => 9,
      'y' => 18,
      'length' => 1,
      'x' => 33
    },
    {
      'x' => 95,
      'length' => 2,
      'y' => 68,
      'height' => 1
    },
    {
      'height' => 5,
      'y' => 93,
      'length' => 8,
      'x' => 31
    },
    {
      'height' => 3,
      'x' => 68,
      'length' => 5,
      'y' => 91
    },
    {
      'y' => 31,
      'length' => 8,
      'x' => 18,
      'height' => 3
    },
    {
      'height' => 9,
      'y' => 9,
      'length' => 4,
      'x' => 7
    },
    {
      'length' => 0,
      'y' => 81,
      'x' => 27,
      'height' => 9
    },
    {
      'x' => 82,
      'length' => 6,
      'y' => 72,
      'height' => 8
    },
    {
      'height' => 8,
      'length' => 1,
      'y' => 24,
      'x' => 59
    },
    {
      'length' => 4,
      'y' => 95,
      'x' => 44,
      'height' => 6
    },
    {
      'y' => 93,
      'length' => 1,
      'x' => 90,
      'height' => 8
    },
    {
      'height' => 0,
      'length' => 1,
      'x' => 53,
      'y' => 19
    },
    {
      'height' => 0,
      'y' => 75,
      'length' => 8,
      'x' => 14
    },
    {
      'length' => 7,
      'x' => 9,
      'y' => 76,
      'height' => 7
    },
    {
      'length' => 8,
      'x' => 9,
      'y' => 50,
      'height' => 2
    },
    {
      'length' => 6,
      'y' => 83,
      'x' => 21,
      'height' => 0
    },
    {
      'x' => 35,
      'length' => 9,
      'y' => 98,
      'height' => 2
    },
    {
      'length' => 0,
      'x' => 98,
      'y' => 52,
      'height' => 3
    },
    {
      'y' => 72,
      'length' => 3,
      'x' => 84,
      'height' => 5
    },
    {
      'y' => 23,
      'length' => 7,
      'x' => 11,
      'height' => 3
    },
    {
      'height' => 0,
      'y' => 5,
      'length' => 1,
      'x' => 97
    },
    {
      'length' => 5,
      'y' => 32,
      'x' => 68,
      'height' => 9
    },
    {
      'height' => 2,
      'x' => 70,
      'length' => 1,
      'y' => 97
    },
    {
      'y' => 76,
      'length' => 4,
      'x' => 26,
      'height' => 3
    },
    {
      'height' => 4,
      'y' => 23,
      'length' => 5,
      'x' => 37
    },
    {
      'height' => 8,
      'x' => 28,
      'length' => 5,
      'y' => 47
    },
    {
      'y' => 39,
      'length' => 5,
      'x' => 12,
      'height' => 1
    },
    {
      'x' => 86,
      'length' => 0,
      'y' => 83,
      'height' => 1
    },
    {
      'length' => 0,
      'y' => 42,
      'x' => 5,
      'height' => 9
    },
    {
      'height' => 2,
      'x' => 35,
      'length' => 6,
      'y' => 42
    },
    {
      'length' => 5,
      'x' => 31,
      'y' => 87,
      'height' => 7
    },
    {
      'height' => 2,
      'x' => 44,
      'length' => 9,
      'y' => 55
    },
    {
      'y' => 32,
      'length' => 0,
      'x' => 22,
      'height' => 8
    },
    {
      'x' => 75,
      'length' => 5,
      'y' => 43,
      'height' => 9
    },
    {
      'y' => 87,
      'length' => 1,
      'x' => 30,
      'height' => 6
    },
    {
      'height' => 9,
      'x' => 42,
      'length' => 1,
      'y' => 37
    },
    {
      'y' => 46,
      'length' => 2,
      'x' => 14,
      'height' => 3
    },
    {
      'y' => 83,
      'length' => 0,
      'x' => 65,
      'height' => 9
    },
    {
      'length' => 6,
      'y' => 47,
      'x' => 35,
      'height' => 1
    },
    {
      'x' => 98,
      'length' => 1,
      'y' => 97,
      'height' => 3
    },
    {
      'length' => 0,
      'y' => 94,
      'x' => 70,
      'height' => 7
    },
    {
      'length' => 6,
      'y' => 13,
      'x' => 21,
      'height' => 0
    },
    {
      'y' => 48,
      'length' => 4,
      'x' => 98,
      'height' => 4
    },
    {
      'height' => 7,
      'length' => 6,
      'x' => 29,
      'y' => 70
    },
    {
      'y' => 73,
      'length' => 0,
      'x' => 27,
      'height' => 3
    },
    {
      'height' => 9,
      'length' => 3,
      'x' => 77,
      'y' => 40
    },
    {
      'length' => 6,
      'x' => 16,
      'y' => 63,
      'height' => 2
    },
    {
      'length' => 0,
      'y' => 17,
      'x' => 50,
      'height' => 2
    },
    {
      'x' => 91,
      'length' => 6,
      'y' => 60,
      'height' => 5
    },
    {
      'height' => 0,
      'length' => 6,
      'x' => 27,
      'y' => 76
    },
    {
      'y' => 23,
      'length' => 2,
      'x' => 45,
      'height' => 8
    },
    {
      'y' => 80,
      'length' => 9,
      'x' => 7,
      'height' => 4
    },
    {
      'y' => 26,
      'length' => 9,
      'x' => 47,
      'height' => 6
    },
    {
      'length' => 7,
      'y' => 82,
      'x' => 45,
      'height' => 7
    },
    {
      'x' => 19,
      'length' => 3,
      'y' => 62,
      'height' => 9
    },
    {
      'y' => 52,
      'length' => 9,
      'x' => 35,
      'height' => 4
    },
    {
      'y' => 21,
      'length' => 6,
      'x' => 16,
      'height' => 5
    },
    {
      'height' => 6,
      'x' => 12,
      'length' => 6,
      'y' => 41
    },
    {
      'height' => 5,
      'y' => 45,
      'length' => 7,
      'x' => 96
    },
    {
      'x' => 50,
      'length' => 5,
      'y' => 82,
      'height' => 8
    },
    {
      'length' => 0,
      'y' => 35,
      'x' => 63,
      'height' => 6
    },
    {
      'x' => 27,
      'length' => 8,
      'y' => 94,
      'height' => 6
    },
    {
      'height' => 7,
      'length' => 8,
      'x' => 98,
      'y' => 58
    },
    {
      'height' => 2,
      'x' => 11,
      'length' => 2,
      'y' => 93
    },
    {
      'height' => 9,
      'y' => 34,
      'length' => 8,
      'x' => 54
    },
    {
      'height' => 0,
      'x' => 12,
      'length' => 4,
      'y' => 29
    },
    {
      'height' => 8,
      'y' => 11,
      'length' => 0,
      'x' => 11
    },
    {
      'height' => 9,
      'x' => 10,
      'length' => 2,
      'y' => 83
    },
    {
      'height' => 3,
      'y' => 34,
      'length' => 0,
      'x' => 31
    },
    {
      'height' => 2,
      'y' => 99,
      'length' => 1,
      'x' => 15
    },
    {
      'length' => 3,
      'y' => 89,
      'x' => 62,
      'height' => 9
    },
    {
      'x' => 87,
      'length' => 2,
      'y' => 25,
      'height' => 8
    },
    {
      'height' => 3,
      'length' => 4,
      'y' => 55,
      'x' => 45
    },
    {
      'height' => 3,
      'length' => 6,
      'y' => 12,
      'x' => 78
    },
    {
      'y' => 41,
      'length' => 0,
      'x' => 93,
      'height' => 1
    },
    {
      'length' => 8,
      'x' => 67,
      'y' => 99,
      'height' => 2
    },
    {
      'height' => 2,
      'y' => 70,
      'length' => 7,
      'x' => 66
    },
    {
      'length' => 6,
      'x' => 36,
      'y' => 22,
      'height' => 8
    },
    {
      'height' => 9,
      'length' => 1,
      'x' => 2,
      'y' => 8
    },
    {
      'height' => 4,
      'length' => 3,
      'y' => 22,
      'x' => 68
    },
    {
      'x' => 65,
      'length' => 3,
      'y' => 41,
      'height' => 2
    },
    {
      'length' => 7,
      'x' => 46,
      'y' => 14,
      'height' => 6
    },
    {
      'y' => 12,
      'length' => 6,
      'x' => 7,
      'height' => 3
    },
    {
      'height' => 8,
      'y' => 48,
      'length' => 4,
      'x' => 31
    },
    {
      'height' => 8,
      'y' => 3,
      'length' => 6,
      'x' => 22
    },
    {
      'length' => 3,
      'y' => 52,
      'x' => 68,
      'height' => 0
    },
    {
      'x' => 68,
      'length' => 4,
      'y' => 75,
      'height' => 9
    },
    {
      'height' => 5,
      'y' => 59,
      'length' => 0,
      'x' => 68
    },
    {
      'height' => 9,
      'y' => 55,
      'length' => 1,
      'x' => 33
    },
    {
      'x' => 53,
      'length' => 1,
      'y' => 44,
      'height' => 0
    },
    {
      'y' => 21,
      'length' => 0,
      'x' => 67,
      'height' => 4
    },
    {
      'x' => 32,
      'length' => 1,
      'y' => 77,
      'height' => 3
    },
    {
      'length' => 9,
      'y' => 42,
      'x' => 91,
      'height' => 9
    },
    {
      'height' => 7,
      'x' => 6,
      'length' => 6,
      'y' => 45
    },
    {
      'length' => 7,
      'x' => 27,
      'y' => 99,
      'height' => 3
    },
    {
      'x' => 49,
      'length' => 5,
      'y' => 61,
      'height' => 3
    },
    {
      'height' => 6,
      'y' => 51,
      'length' => 8,
      'x' => 74
    },
    {
      'x' => 27,
      'length' => 6,
      'y' => 86,
      'height' => 0
    },
    {
      'y' => 17,
      'length' => 8,
      'x' => 33,
      'height' => 0
    },
    {
      'height' => 8,
      'x' => 67,
      'length' => 6,
      'y' => 68
    },
    {
      'height' => 9,
      'y' => 68,
      'length' => 5,
      'x' => 83
    },
    {
      'y' => 22,
      'length' => 9,
      'x' => 46,
      'height' => 8
    },
    {
      'length' => 3,
      'y' => 77,
      'x' => 65,
      'height' => 7
    },
    {
      'height' => 5,
      'x' => 26,
      'length' => 8,
      'y' => 83
    },
    {
      'height' => 3,
      'length' => 3,
      'y' => 49,
      'x' => 79
    },
    {
      'length' => 2,
      'y' => 16,
      'x' => 14,
      'height' => 3
    },
    {
      'height' => 8,
      'y' => 63,
      'length' => 6,
      'x' => 76
    },
    {
      'length' => 1,
      'x' => 31,
      'y' => 79,
      'height' => 7
    },
    {
      'y' => 1,
      'length' => 5,
      'x' => 36,
      'height' => 9
    },
    {
      'height' => 3,
      'length' => 0,
      'x' => 15,
      'y' => 15
    },
    {
      'length' => 0,
      'x' => 72,
      'y' => 92,
      'height' => 4
    },
    {
      'height' => 7,
      'length' => 7,
      'y' => 24,
      'x' => 97
    },
    {
      'height' => 9,
      'x' => 15,
      'length' => 5,
      'y' => 95
    },
    {
      'length' => 3,
      'x' => 90,
      'y' => 85,
      'height' => 1
    },
    {
      'height' => 0,
      'y' => 72,
      'length' => 4,
      'x' => 57
    },
    {
      'height' => 8,
      'y' => 65,
      'length' => 5,
      'x' => 1
    },
    {
      'y' => 45,
      'length' => 3,
      'x' => 96,
      'height' => 5
    },
    {
      'height' => 6,
      'length' => 0,
      'y' => 1,
      'x' => 21
    },
    {
      'height' => 2,
      'x' => 77,
      'length' => 4,
      'y' => 97
    },
    {
      'y' => 61,
      'length' => 7,
      'x' => 42,
      'height' => 7
    },
    {
      'y' => 19,
      'length' => 5,
      'x' => 48,
      'height' => 8
    },
    {
      'height' => 5,
      'x' => 98,
      'length' => 0,
      'y' => 20
    },
    {
      'height' => 5,
      'y' => 72,
      'length' => 6,
      'x' => 66
    },
    {
      'x' => 15,
      'length' => 0,
      'y' => 29,
      'height' => 1
    },
    {
      'height' => 8,
      'length' => 8,
      'y' => 79,
      'x' => 27
    },
    {
      'x' => 56,
      'length' => 8,
      'y' => 81,
      'height' => 0
    },
    {
      'length' => 7,
      'x' => 65,
      'y' => 68,
      'height' => 2
    },
    {
      'height' => 2,
      'x' => 39,
      'length' => 5,
      'y' => 39
    },
    {
      'y' => 61,
      'length' => 1,
      'x' => 5,
      'height' => 0
    },
    {
      'x' => 80,
      'length' => 3,
      'y' => 98,
      'height' => 7
    },
    {
      'y' => 36,
      'length' => 0,
      'x' => 85,
      'height' => 9
    },
    {
      'height' => 3,
      'x' => 92,
      'length' => 0,
      'y' => 60
    },
    {
      'height' => 1,
      'y' => 35,
      'length' => 3,
      'x' => 0
    },
    {
      'height' => 5,
      'y' => 60,
      'length' => 6,
      'x' => 3
    },
    {
      'length' => 9,
      'y' => 37,
      'x' => 32,
      'height' => 3
    },
    {
      'x' => 55,
      'length' => 4,
      'y' => 61,
      'height' => 5
    },
    {
      'length' => 9,
      'y' => 14,
      'x' => 44,
      'height' => 7
    },
    {
      'length' => 0,
      'y' => 36,
      'x' => 35,
      'height' => 6
    },
    {
      'y' => 52,
      'length' => 2,
      'x' => 4,
      'height' => 1
    },
    {
      'length' => 3,
      'x' => 55,
      'y' => 94,
      'height' => 5
    },
    {
      'y' => 8,
      'length' => 4,
      'x' => 7,
      'height' => 7
    },
    {
      'height' => 4,
      'length' => 7,
      'x' => 12,
      'y' => 61
    },
    {
      'height' => 8,
      'length' => 0,
      'x' => 37,
      'y' => 96
    },
    {
      'length' => 0,
      'y' => 39,
      'x' => 62,
      'height' => 5
    },
    {
      'height' => 3,
      'x' => 78,
      'length' => 3,
      'y' => 21
    },
    {
      'length' => 6,
      'x' => 57,
      'y' => 49,
      'height' => 0
    },
    {
      'y' => 54,
      'length' => 2,
      'x' => 61,
      'height' => 6
    },
    {
      'height' => 0,
      'y' => 65,
      'length' => 0,
      'x' => 92
    },
    {
      'height' => 4,
      'y' => 60,
      'length' => 6,
      'x' => 53
    },
    {
      'length' => 5,
      'y' => 44,
      'x' => 71,
      'height' => 0
    },
    {
      'height' => 5,
      'x' => 86,
      'length' => 8,
      'y' => 85
    },
    {
      'y' => 53,
      'length' => 6,
      'x' => 8,
      'height' => 5
    },
    {
      'height' => 5,
      'y' => 91,
      'length' => 1,
      'x' => 97
    },
    {
      'x' => 16,
      'length' => 9,
      'y' => 33,
      'height' => 1
    },
    {
      'y' => 90,
      'length' => 4,
      'x' => 38,
      'height' => 8
    },
    {
      'x' => 20,
      'length' => 5,
      'y' => 82,
      'height' => 8
    },
    {
      'height' => 2,
      'length' => 1,
      'y' => 60,
      'x' => 71
    },
    {
      'x' => 49,
      'length' => 9,
      'y' => 58,
      'height' => 8
    },
    {
      'length' => 9,
      'x' => 8,
      'y' => 36,
      'height' => 9
    },
    {
      'x' => 31,
      'length' => 7,
      'y' => 64,
      'height' => 3
    },
    {
      'y' => 77,
      'length' => 4,
      'x' => 42,
      'height' => 7
    },
    {
      'height' => 0,
      'x' => 16,
      'length' => 0,
      'y' => 9
    },
    {
      'y' => 60,
      'length' => 8,
      'x' => 82,
      'height' => 8
    },
    {
      'x' => 88,
      'length' => 4,
      'y' => 94,
      'height' => 6
    },
    {
      'y' => 12,
      'length' => 3,
      'x' => 19,
      'height' => 3
    },
    {
      'y' => 94,
      'length' => 9,
      'x' => 32,
      'height' => 1
    },
    {
      'height' => 1,
      'length' => 6,
      'y' => 23,
      'x' => 75
    },
    {
      'x' => 22,
      'length' => 4,
      'y' => 35,
      'height' => 8
    },
    {
      'length' => 3,
      'y' => 68,
      'x' => 84,
      'height' => 0
    },
    {
      'length' => 7,
      'y' => 95,
      'x' => 83,
      'height' => 1
    },
    {
      'height' => 2,
      'y' => 76,
      'length' => 0,
      'x' => 80
    },
    {
      'length' => 1,
      'x' => 83,
      'y' => 76,
      'height' => 6
    },
    {
      'y' => 19,
      'length' => 9,
      'x' => 5,
      'height' => 8
    },
    {
      'height' => 5,
      'length' => 1,
      'x' => 35,
      'y' => 84
    },
    {
      'height' => 3,
      'length' => 7,
      'x' => 3,
      'y' => 52
    },
    {
      'length' => 4,
      'y' => 6,
      'x' => 23,
      'height' => 3
    },
    {
      'x' => 56,
      'length' => 8,
      'y' => 38,
      'height' => 2
    },
    {
      'length' => 7,
      'x' => 45,
      'y' => 38,
      'height' => 3
    },
    {
      'height' => 3,
      'y' => 6,
      'length' => 6,
      'x' => 54
    },
    {
      'height' => 9,
      'y' => 10,
      'length' => 1,
      'x' => 71
    },
    {
      'height' => 3,
      'y' => 39,
      'length' => 5,
      'x' => 81
    },
    {
      'length' => 8,
      'y' => 86,
      'x' => 3,
      'height' => 6
    },
    {
      'height' => 8,
      'x' => 99,
      'length' => 9,
      'y' => 61
    },
    {
      'y' => 79,
      'length' => 8,
      'x' => 92,
      'height' => 1
    },
    {
      'height' => 7,
      'y' => 17,
      'length' => 0,
      'x' => 77
    },
    {
      'height' => 9,
      'x' => 38,
      'length' => 3,
      'y' => 73
    },
    {
      'y' => 37,
      'length' => 3,
      'x' => 18,
      'height' => 2
    },
    {
      'height' => 2,
      'x' => 48,
      'length' => 4,
      'y' => 85
    },
    {
      'length' => 8,
      'y' => 72,
      'x' => 72,
      'height' => 1
    },
    {
      'x' => 87,
      'length' => 4,
      'y' => 23,
      'height' => 9
    },
    {
      'height' => 1,
      'length' => 9,
      'x' => 94,
      'y' => 64
    },
    {
      'height' => 4,
      'x' => 86,
      'length' => 7,
      'y' => 60
    },
    {
      'height' => 8,
      'y' => 18,
      'length' => 6,
      'x' => 41
    },
    {
      'height' => 0,
      'x' => 98,
      'length' => 7,
      'y' => 46
    },
    {
      'height' => 7,
      'y' => 14,
      'length' => 6,
      'x' => 53
    },
    {
      'height' => 0,
      'x' => 23,
      'length' => 0,
      'y' => 89
    },
    {
      'y' => 46,
      'length' => 1,
      'x' => 77,
      'height' => 0
    },
    {
      'height' => 6,
      'y' => 6,
      'length' => 9,
      'x' => 17
    },
    {
      'height' => 0,
      'length' => 3,
      'y' => 97,
      'x' => 18
    },
    {
      'height' => 1,
      'x' => 15,
      'length' => 0,
      'y' => 3
    },
    {
      'length' => 7,
      'y' => 78,
      'x' => 2,
      'height' => 0
    },
    {
      'height' => 6,
      'length' => 1,
      'y' => 59,
      'x' => 86
    },
    {
      'height' => 2,
      'y' => 7,
      'length' => 5,
      'x' => 44
    },
    {
      'length' => 6,
      'x' => 8,
      'y' => 25,
      'height' => 0
    },
    {
      'y' => 27,
      'length' => 0,
      'x' => 2,
      'height' => 9
    },
    {
      'length' => 4,
      'x' => 40,
      'y' => 12,
      'height' => 5
    },
    {
      'length' => 2,
      'x' => 63,
      'y' => 17,
      'height' => 1
    },
    {
      'length' => 6,
      'y' => 16,
      'x' => 24,
      'height' => 4
    },
    {
      'x' => 8,
      'length' => 8,
      'y' => 62,
      'height' => 4
    },
    {
      'length' => 4,
      'x' => 96,
      'y' => 82,
      'height' => 4
    },
    {
      'y' => 52,
      'length' => 4,
      'x' => 31,
      'height' => 5
    },
    {
      'y' => 13,
      'length' => 0,
      'x' => 41,
      'height' => 1
    },
    {
      'y' => 29,
      'length' => 7,
      'x' => 63,
      'height' => 5
    },
    {
      'height' => 5,
      'length' => 1,
      'y' => 43,
      'x' => 60
    },
    {
      'x' => 84,
      'length' => 8,
      'y' => 98,
      'height' => 1
    },
    {
      'height' => 0,
      'y' => 69,
      'length' => 5,
      'x' => 34
    },
    {
      'height' => 5,
      'y' => 87,
      'length' => 4,
      'x' => 42
    },
    {
      'x' => 96,
      'length' => 0,
      'y' => 87,
      'height' => 8
    },
    {
      'height' => 3,
      'y' => 16,
      'length' => 7,
      'x' => 23
    },
    {
      'height' => 7,
      'x' => 20,
      'length' => 1,
      'y' => 23
    },
    {
      'height' => 6,
      'length' => 5,
      'y' => 56,
      'x' => 22
    },
    {
      'x' => 42,
      'length' => 5,
      'y' => 45,
      'height' => 9
    },
    {
      'height' => 8,
      'length' => 1,
      'x' => 93,
      'y' => 78
    },
    {
      'x' => 13,
      'length' => 1,
      'y' => 65,
      'height' => 4
    },
    {
      'y' => 93,
      'length' => 3,
      'x' => 13,
      'height' => 2
    },
    {
      'height' => 2,
      'x' => 54,
      'length' => 0,
      'y' => 48
    },
    {
      'height' => 2,
      'y' => 39,
      'length' => 9,
      'x' => 31
    },
    {
      'height' => 2,
      'x' => 71,
      'length' => 7,
      'y' => 85
    },
    {
      'height' => 4,
      'y' => 30,
      'length' => 1,
      'x' => 99
    },
    {
      'height' => 9,
      'y' => 7,
      'length' => 4,
      'x' => 23
    },
    {
      'length' => 4,
      'y' => 10,
      'x' => 90,
      'height' => 8
    },
    {
      'x' => 13,
      'length' => 5,
      'y' => 7,
      'height' => 7
    },
    {
      'length' => 4,
      'y' => 46,
      'x' => 49,
      'height' => 7
    },
    {
      'length' => 6,
      'y' => 61,
      'x' => 93,
      'height' => 1
    },
    {
      'y' => 3,
      'length' => 9,
      'x' => 65,
      'height' => 7
    },
    {
      'height' => 8,
      'length' => 1,
      'x' => 15,
      'y' => 43
    },
    {
      'y' => 65,
      'length' => 6,
      'x' => 5,
      'height' => 5
    },
    {
      'height' => 9,
      'length' => 4,
      'x' => 75,
      'y' => 11
    },
    {
      'height' => 6,
      'length' => 2,
      'x' => 84,
      'y' => 57
    },
    {
      'height' => 3,
      'length' => 6,
      'y' => 36,
      'x' => 29
    },
    {
      'x' => 42,
      'length' => 8,
      'y' => 88,
      'height' => 0
    },
    {
      'height' => 3,
      'length' => 8,
      'x' => 33,
      'y' => 37
    },
    {
      'y' => 70,
      'length' => 0,
      'x' => 38,
      'height' => 8
    },
    {
      'y' => 71,
      'length' => 3,
      'x' => 81,
      'height' => 3
    },
    {
      'y' => 16,
      'length' => 5,
      'x' => 63,
      'height' => 5
    },
    {
      'height' => 5,
      'length' => 0,
      'y' => 76,
      'x' => 87
    },
    {
      'height' => 6,
      'x' => 53,
      'length' => 0,
      'y' => 92
    },
    {
      'height' => 5,
      'y' => 61,
      'length' => 4,
      'x' => 32
    },
    {
      'height' => 4,
      'y' => 8,
      'length' => 5,
      'x' => 92
    },
    {
      'x' => 67,
      'length' => 6,
      'y' => 5,
      'height' => 5
    },
    {
      'y' => 56,
      'length' => 6,
      'x' => 45,
      'height' => 5
    },
    {
      'x' => 20,
      'length' => 8,
      'y' => 44,
      'height' => 4
    },
    {
      'length' => 8,
      'y' => 83,
      'x' => 44,
      'height' => 3
    },
    {
      'x' => 97,
      'length' => 8,
      'y' => 45,
      'height' => 0
    },
    {
      'height' => 7,
      'length' => 5,
      'x' => 95,
      'y' => 51
    },
    {
      'x' => 15,
      'length' => 1,
      'y' => 57,
      'height' => 5
    },
    {
      'height' => 4,
      'y' => 76,
      'length' => 9,
      'x' => 11
    },
    {
      'height' => 1,
      'x' => 15,
      'length' => 6,
      'y' => 96
    },
    {
      'y' => 69,
      'length' => 9,
      'x' => 47,
      'height' => 9
    },
    {
      'height' => 4,
      'x' => 51,
      'length' => 0,
      'y' => 67
    },
    {
      'height' => 9,
      'y' => 85,
      'length' => 4,
      'x' => 88
    },
    {
      'height' => 0,
      'y' => 65,
      'length' => 9,
      'x' => 34
    },
    {
      'height' => 6,
      'length' => 8,
      'y' => 76,
      'x' => 14
    },
    {
      'height' => 1,
      'x' => 17,
      'length' => 6,
      'y' => 63
    },
    {
      'length' => 7,
      'y' => 85,
      'x' => 20,
      'height' => 7
    },
    {
      'length' => 7,
      'y' => 36,
      'x' => 16,
      'height' => 7
    },
    {
      'height' => 2,
      'y' => 81,
      'length' => 9,
      'x' => 29
    },
    {
      'length' => 9,
      'x' => 20,
      'y' => 57,
      'height' => 1
    },
    {
      'height' => 6,
      'y' => 86,
      'length' => 3,
      'x' => 51
    },
    {
      'length' => 3,
      'x' => 17,
      'y' => 13,
      'height' => 3
    },
    {
      'height' => 4,
      'length' => 8,
      'x' => 4,
      'y' => 20
    },
    {
      'length' => 0,
      'y' => 40,
      'x' => 63,
      'height' => 0
    },
    {
      'x' => 4,
      'length' => 9,
      'y' => 63,
      'height' => 3
    },
    {
      'length' => 7,
      'x' => 4,
      'y' => 14,
      'height' => 6
    },
    {
      'height' => 9,
      'y' => 68,
      'length' => 7,
      'x' => 62
    },
    {
      'y' => 89,
      'length' => 9,
      'x' => 88,
      'height' => 6
    },
    {
      'height' => 7,
      'y' => 99,
      'length' => 5,
      'x' => 24
    },
    {
      'length' => 1,
      'y' => 17,
      'x' => 71,
      'height' => 5
    },
    {
      'height' => 6,
      'x' => 63,
      'length' => 1,
      'y' => 46
    },
    {
      'height' => 4,
      'y' => 31,
      'length' => 5,
      'x' => 80
    },
    {
      'y' => 90,
      'length' => 2,
      'x' => 62,
      'height' => 2
    },
    {
      'height' => 6,
      'x' => 9,
      'length' => 2,
      'y' => 69
    },
    {
      'y' => 86,
      'length' => 0,
      'x' => 39,
      'height' => 9
    },
    {
      'x' => 31,
      'length' => 5,
      'y' => 89,
      'height' => 2
    },
    {
      'height' => 5,
      'length' => 1,
      'y' => 34,
      'x' => 84
    },
    {
      'height' => 2,
      'x' => 86,
      'length' => 1,
      'y' => 19
    },
    {
      'length' => 6,
      'x' => 4,
      'y' => 78,
      'height' => 1
    },
    {
      'height' => 9,
      'x' => 26,
      'length' => 2,
      'y' => 88
    },
    {
      'height' => 6,
      'y' => 84,
      'length' => 4,
      'x' => 22
    },
    {
      'x' => 54,
      'length' => 9,
      'y' => 39,
      'height' => 9
    },
    {
      'y' => 8,
      'length' => 9,
      'x' => 17,
      'height' => 0
    },
    {
      'height' => 4,
      'x' => 71,
      'length' => 1,
      'y' => 93
    },
    {
      'y' => 34,
      'length' => 2,
      'x' => 22,
      'height' => 5
    },
    {
      'y' => 30,
      'length' => 0,
      'x' => 97,
      'height' => 2
    },
    {
      'length' => 6,
      'y' => 52,
      'x' => 98,
      'height' => 3
    },
    {
      'height' => 3,
      'x' => 97,
      'length' => 1,
      'y' => 91
    },
    {
      'length' => 8,
      'y' => 95,
      'x' => 40,
      'height' => 2
    },
    {
      'height' => 9,
      'length' => 9,
      'y' => 41,
      'x' => 73
    },
    {
      'height' => 0,
      'y' => 0,
      'length' => 2,
      'x' => 32
    },
    {
      'height' => 1,
      'length' => 5,
      'x' => 11,
      'y' => 52
    },
    {
      'y' => 43,
      'length' => 0,
      'x' => 93,
      'height' => 9
    },
    {
      'height' => 0,
      'length' => 9,
      'x' => 17,
      'y' => 37
    },
    {
      'length' => 7,
      'x' => 15,
      'y' => 17,
      'height' => 1
    },
    {
      'length' => 5,
      'y' => 35,
      'x' => 53,
      'height' => 2
    },
    {
      'height' => 6,
      'x' => 69,
      'length' => 4,
      'y' => 70
    },
    {
      'height' => 2,
      'length' => 9,
      'x' => 19,
      'y' => 9
    },
    {
      'y' => 65,
      'length' => 0,
      'x' => 21,
      'height' => 3
    },
    {
      'y' => 11,
      'length' => 7,
      'x' => 15,
      'height' => 0
    },
    {
      'height' => 2,
      'y' => 68,
      'length' => 2,
      'x' => 51
    },
    {
      'height' => 1,
      'length' => 2,
      'y' => 95,
      'x' => 79
    },
    {
      'height' => 7,
      'x' => 98,
      'length' => 8,
      'y' => 41
    },
    {
      'height' => 1,
      'y' => 23,
      'length' => 0,
      'x' => 8
    },
    {
      'y' => 20,
      'length' => 6,
      'x' => 16,
      'height' => 5
    },
    {
      'x' => 7,
      'length' => 5,
      'y' => 61,
      'height' => 0
    },
    {
      'y' => 13,
      'length' => 4,
      'x' => 14,
      'height' => 5
    },
    {
      'height' => 0,
      'x' => 82,
      'length' => 4,
      'y' => 19
    },
    {
      'height' => 2,
      'length' => 1,
      'y' => 77,
      'x' => 0
    },
    {
      'height' => 2,
      'x' => 34,
      'length' => 5,
      'y' => 70
    },
    {
      'height' => 3,
      'length' => 7,
      'x' => 27,
      'y' => 55
    },
    {
      'x' => 51,
      'length' => 6,
      'y' => 5,
      'height' => 3
    },
    {
      'height' => 7,
      'y' => 56,
      'length' => 3,
      'x' => 57
    },
    {
      'x' => 30,
      'length' => 7,
      'y' => 24,
      'height' => 6
    },
    {
      'y' => 7,
      'length' => 4,
      'x' => 34,
      'height' => 7
    },
    {
      'height' => 9,
      'x' => 65,
      'length' => 4,
      'y' => 23
    },
    {
      'y' => 81,
      'length' => 9,
      'x' => 34,
      'height' => 6
    },
    {
      'height' => 5,
      'y' => 70,
      'length' => 2,
      'x' => 61
    },
    {
      'height' => 5,
      'length' => 5,
      'y' => 16,
      'x' => 27
    },
    {
      'height' => 6,
      'x' => 32,
      'length' => 7,
      'y' => 39
    },
    {
      'length' => 0,
      'y' => 42,
      'x' => 56,
      'height' => 6
    },
    {
      'length' => 4,
      'y' => 89,
      'x' => 23,
      'height' => 1
    },
    {
      'height' => 4,
      'y' => 37,
      'length' => 3,
      'x' => 70
    },
    {
      'height' => 0,
      'length' => 7,
      'x' => 90,
      'y' => 97
    },
    {
      'height' => 0,
      'y' => 64,
      'length' => 6,
      'x' => 94
    },
    {
      'height' => 0,
      'length' => 8,
      'x' => 36,
      'y' => 27
    },
    {
      'length' => 3,
      'x' => 61,
      'y' => 2,
      'height' => 7
    },
    {
      'height' => 8,
      'length' => 5,
      'y' => 94,
      'x' => 69
    },
    {
      'height' => 7,
      'x' => 34,
      'length' => 6,
      'y' => 0
    },
    {
      'length' => 8,
      'x' => 96,
      'y' => 27,
      'height' => 8
    },
    {
      'y' => 67,
      'length' => 0,
      'x' => 57,
      'height' => 3
    },
    {
      'y' => 46,
      'length' => 1,
      'x' => 13,
      'height' => 0
    },
    {
      'y' => 88,
      'length' => 4,
      'x' => 8,
      'height' => 6
    },
    {
      'length' => 7,
      'y' => 69,
      'x' => 0,
      'height' => 9
    },
    {
      'x' => 64,
      'length' => 0,
      'y' => 20,
      'height' => 5
    },
    {
      'height' => 7,
      'y' => 74,
      'length' => 5,
      'x' => 26
    },
    {
      'y' => 38,
      'length' => 7,
      'x' => 32,
      'height' => 1
    },
    {
      'height' => 0,
      'x' => 8,
      'length' => 7,
      'y' => 32
    },
    {
      'height' => 0,
      'y' => 3,
      'length' => 9,
      'x' => 25
    },
    {
      'height' => 3,
      'x' => 82,
      'length' => 9,
      'y' => 41
    },
    {
      'height' => 2,
      'length' => 8,
      'y' => 44,
      'x' => 56
    },
    {
      'x' => 98,
      'length' => 0,
      'y' => 36,
      'height' => 6
    },
    {
      'length' => 8,
      'x' => 65,
      'y' => 60,
      'height' => 8
    },
    {
      'x' => 10,
      'length' => 2,
      'y' => 84,
      'height' => 6
    },
    {
      'y' => 34,
      'length' => 8,
      'x' => 43,
      'height' => 5
    },
    {
      'x' => 28,
      'length' => 9,
      'y' => 23,
      'height' => 2
    },
    {
      'y' => 47,
      'length' => 4,
      'x' => 59,
      'height' => 9
    },
    {
      'x' => 37,
      'length' => 3,
      'y' => 48,
      'height' => 7
    },
    {
      'y' => 92,
      'length' => 2,
      'x' => 13,
      'height' => 2
    },
    {
      'y' => 89,
      'length' => 6,
      'x' => 18,
      'height' => 8
    },
    {
      'length' => 6,
      'y' => 46,
      'x' => 52,
      'height' => 7
    },
    {
      'x' => 48,
      'length' => 7,
      'y' => 15,
      'height' => 8
    },
    {
      'height' => 0,
      'length' => 8,
      'y' => 38,
      'x' => 29
    },
    {
      'height' => 2,
      'length' => 4,
      'y' => 75,
      'x' => 14
    },
    {
      'height' => 2,
      'y' => 67,
      'length' => 1,
      'x' => 28
    },
    {
      'length' => 1,
      'x' => 10,
      'y' => 73,
      'height' => 2
    },
    {
      'y' => 32,
      'length' => 8,
      'x' => 13,
      'height' => 3
    },
    {
      'height' => 6,
      'length' => 5,
      'x' => 88,
      'y' => 72
    },
    {
      'height' => 3,
      'length' => 3,
      'x' => 23,
      'y' => 44
    },
    {
      'height' => 6,
      'length' => 7,
      'y' => 77,
      'x' => 66
    },
    {
      'x' => 3,
      'length' => 1,
      'y' => 36,
      'height' => 5
    },
    {
      'length' => 4,
      'x' => 94,
      'y' => 13,
      'height' => 8
    },
    {
      'height' => 0,
      'y' => 46,
      'length' => 5,
      'x' => 23
    },
    {
      'y' => 97,
      'length' => 7,
      'x' => 71,
      'height' => 0
    },
    {
      'height' => 0,
      'y' => 69,
      'length' => 3,
      'x' => 3
    },
    {
      'height' => 5,
      'length' => 4,
      'y' => 51,
      'x' => 88
    },
    {
      'height' => 1,
      'x' => 79,
      'length' => 7,
      'y' => 66
    },
    {
      'y' => 45,
      'length' => 1,
      'x' => 61,
      'height' => 1
    },
    {
      'y' => 20,
      'length' => 1,
      'x' => 99,
      'height' => 6
    },
    {
      'x' => 68,
      'length' => 8,
      'y' => 28,
      'height' => 5
    },
    {
      'y' => 57,
      'length' => 3,
      'x' => 62,
      'height' => 3
    },
    {
      'height' => 6,
      'x' => 64,
      'length' => 6,
      'y' => 42
    },
    {
      'length' => 6,
      'y' => 13,
      'x' => 9,
      'height' => 0
    },
    {
      'x' => 11,
      'length' => 0,
      'y' => 16,
      'height' => 8
    },
    {
      'length' => 9,
      'x' => 3,
      'y' => 26,
      'height' => 5
    },
    {
      'x' => 77,
      'length' => 1,
      'y' => 55,
      'height' => 2
    },
    {
      'height' => 5,
      'y' => 34,
      'length' => 9,
      'x' => 12
    },
    {
      'height' => 4,
      'x' => 95,
      'length' => 1,
      'y' => 61
    },
    {
      'y' => 12,
      'length' => 2,
      'x' => 13,
      'height' => 5
    },
    {
      'x' => 96,
      'length' => 4,
      'y' => 17,
      'height' => 8
    },
    {
      'y' => 69,
      'length' => 5,
      'x' => 87,
      'height' => 8
    },
    {
      'height' => 5,
      'y' => 66,
      'length' => 4,
      'x' => 41
    },
    {
      'length' => 2,
      'y' => 96,
      'x' => 80,
      'height' => 0
    },
    {
      'height' => 0,
      'x' => 58,
      'length' => 2,
      'y' => 15
    },
    {
      'length' => 2,
      'y' => 17,
      'x' => 23,
      'height' => 0
    },
    {
      'length' => 2,
      'y' => 5,
      'x' => 17,
      'height' => 3
    },
    {
      'y' => 36,
      'length' => 8,
      'x' => 74,
      'height' => 4
    },
    {
      'length' => 9,
      'x' => 20,
      'y' => 0,
      'height' => 3
    },
    {
      'height' => 8,
      'y' => 61,
      'length' => 3,
      'x' => 4
    },
    {
      'height' => 7,
      'length' => 5,
      'x' => 81,
      'y' => 38
    },
    {
      'height' => 5,
      'length' => 8,
      'x' => 13,
      'y' => 10
    },
    {
      'length' => 1,
      'y' => 65,
      'x' => 21,
      'height' => 8
    },
    {
      'height' => 3,
      'x' => 83,
      'length' => 0,
      'y' => 25
    },
    {
      'height' => 0,
      'length' => 7,
      'x' => 62,
      'y' => 80
    },
    {
      'height' => 5,
      'y' => 19,
      'length' => 9,
      'x' => 76
    },
    {
      'y' => 90,
      'length' => 0,
      'x' => 58,
      'height' => 2
    },
    {
      'y' => 50,
      'length' => 8,
      'x' => 85,
      'height' => 9
    },
    {
      'length' => 1,
      'y' => 36,
      'x' => 98,
      'height' => 3
    },
    {
      'height' => 7,
      'x' => 65,
      'length' => 2,
      'y' => 75
    },
    {
      'height' => 8,
      'y' => 47,
      'length' => 7,
      'x' => 2
    },
    {
      'height' => 8,
      'y' => 55,
      'length' => 5,
      'x' => 5
    },
    {
      'height' => 9,
      'x' => 86,
      'length' => 9,
      'y' => 21
    },
    {
      'height' => 9,
      'y' => 90,
      'length' => 3,
      'x' => 41
    },
    {
      'x' => 27,
      'length' => 8,
      'y' => 9,
      'height' => 4
    },
    {
      'length' => 6,
      'y' => 82,
      'x' => 1,
      'height' => 2
    },
    {
      'x' => 16,
      'length' => 3,
      'y' => 1,
      'height' => 1
    },
    {
      'height' => 4,
      'length' => 3,
      'x' => 1,
      'y' => 24
    },
    {
      'height' => 5,
      'x' => 19,
      'length' => 3,
      'y' => 30
    },
    {
      'height' => 9,
      'y' => 31,
      'length' => 8,
      'x' => 94
    },
    {
      'x' => 88,
      'length' => 3,
      'y' => 45,
      'height' => 0
    },
    {
      'y' => 69,
      'length' => 0,
      'x' => 63,
      'height' => 3
    },
    {
      'height' => 8,
      'x' => 6,
      'length' => 0,
      'y' => 65
    },
    {
      'y' => 31,
      'length' => 7,
      'x' => 20,
      'height' => 5
    },
    {
      'y' => 72,
      'length' => 5,
      'x' => 29,
      'height' => 6
    },
    {
      'height' => 3,
      'length' => 1,
      'y' => 77,
      'x' => 69
    },
    {
      'height' => 2,
      'x' => 7,
      'length' => 3,
      'y' => 48
    },
    {
      'height' => 8,
      'length' => 6,
      'y' => 14,
      'x' => 94
    },
    {
      'length' => 5,
      'y' => 23,
      'x' => 71,
      'height' => 8
    },
    {
      'height' => 8,
      'y' => 45,
      'length' => 8,
      'x' => 47
    },
    {
      'length' => 0,
      'x' => 3,
      'y' => 67,
      'height' => 9
    },
    {
      'height' => 4,
      'y' => 78,
      'length' => 0,
      'x' => 96
    },
    {
      'height' => 2,
      'length' => 9,
      'x' => 58,
      'y' => 97
    },
    {
      'height' => 0,
      'length' => 9,
      'x' => 63,
      'y' => 44
    },
    {
      'length' => 0,
      'y' => 84,
      'x' => 75,
      'height' => 2
    },
    {
      'height' => 8,
      'x' => 74,
      'length' => 9,
      'y' => 64
    },
    {
      'height' => 2,
      'length' => 3,
      'x' => 74,
      'y' => 34
    },
    {
      'y' => 23,
      'length' => 4,
      'x' => 70,
      'height' => 8
    },
    {
      'y' => 3,
      'length' => 9,
      'x' => 63,
      'height' => 6
    },
    {
      'height' => 8,
      'y' => 75,
      'length' => 4,
      'x' => 28
    },
    {
      'height' => 9,
      'length' => 3,
      'y' => 34,
      'x' => 31
    },
    {
      'x' => 35,
      'length' => 7,
      'y' => 40,
      'height' => 1
    },
    {
      'height' => 1,
      'y' => 69,
      'length' => 8,
      'x' => 33
    },
    {
      'height' => 6,
      'y' => 18,
      'length' => 8,
      'x' => 25
    },
    {
      'x' => 49,
      'length' => 1,
      'y' => 34,
      'height' => 3
    },
    {
      'height' => 3,
      'y' => 7,
      'length' => 6,
      'x' => 96
    },
    {
      'height' => 2,
      'x' => 73,
      'length' => 6,
      'y' => 64
    },
    {
      'length' => 6,
      'y' => 47,
      'x' => 50,
      'height' => 9
    },
    {
      'x' => 14,
      'length' => 3,
      'y' => 0,
      'height' => 5
    },
    {
      'length' => 6,
      'x' => 87,
      'y' => 39,
      'height' => 9
    },
    {
      'height' => 8,
      'x' => 37,
      'length' => 3,
      'y' => 33
    },
    {
      'y' => 33,
      'length' => 6,
      'x' => 5,
      'height' => 1
    },
    {
      'height' => 8,
      'x' => 9,
      'length' => 4,
      'y' => 90
    },
    {
      'y' => 48,
      'length' => 8,
      'x' => 17,
      'height' => 1
    },
    {
      'x' => 16,
      'length' => 8,
      'y' => 42,
      'height' => 0
    },
    {
      'height' => 9,
      'y' => 91,
      'length' => 5,
      'x' => 96
    },
    {
      'y' => 7,
      'length' => 7,
      'x' => 44,
      'height' => 5
    },
    {
      'length' => 7,
      'y' => 32,
      'x' => 12,
      'height' => 4
    },
    {
      'x' => 10,
      'length' => 4,
      'y' => 67,
      'height' => 5
    },
    {
      'height' => 3,
      'length' => 4,
      'y' => 43,
      'x' => 86
    },
    {
      'height' => 3,
      'length' => 2,
      'y' => 38,
      'x' => 21
    },
    {
      'height' => 3,
      'y' => 26,
      'length' => 5,
      'x' => 46
    },
    {
      'height' => 1,
      'length' => 5,
      'x' => 17,
      'y' => 60
    },
    {
      'y' => 97,
      'length' => 4,
      'x' => 92,
      'height' => 1
    },
    {
      'height' => 1,
      'length' => 7,
      'x' => 33,
      'y' => 52
    },
    {
      'height' => 0,
      'length' => 4,
      'x' => 16,
      'y' => 41
    },
    {
      'height' => 5,
      'length' => 3,
      'y' => 37,
      'x' => 78
    },
    {
      'height' => 0,
      'x' => 56,
      'length' => 3,
      'y' => 68
    },
    {
      'length' => 2,
      'x' => 71,
      'y' => 9,
      'height' => 8
    },
    {
      'y' => 98,
      'length' => 9,
      'x' => 40,
      'height' => 0
    },
    {
      'y' => 89,
      'length' => 8,
      'x' => 34,
      'height' => 9
    },
    {
      'y' => 70,
      'length' => 6,
      'x' => 25,
      'height' => 5
    },
    {
      'height' => 8,
      'length' => 6,
      'y' => 91,
      'x' => 73
    },
    {
      'x' => 86,
      'length' => 4,
      'y' => 26,
      'height' => 0
    },
    {
      'height' => 2,
      'y' => 9,
      'length' => 3,
      'x' => 83
    },
    {
      'height' => 0,
      'y' => 55,
      'length' => 1,
      'x' => 16
    },
    {
      'height' => 3,
      'x' => 72,
      'length' => 7,
      'y' => 72
    },
    {
      'height' => 2,
      'y' => 85,
      'length' => 3,
      'x' => 68
    },
    {
      'x' => 52,
      'length' => 6,
      'y' => 89,
      'height' => 2
    },
    {
      'height' => 3,
      'length' => 3,
      'y' => 87,
      'x' => 41
    },
    {
      'height' => 1,
      'x' => 97,
      'length' => 9,
      'y' => 68
    },
    {
      'length' => 7,
      'x' => 42,
      'y' => 45,
      'height' => 0
    },
    {
      'x' => 11,
      'length' => 6,
      'y' => 26,
      'height' => 3
    },
    {
      'y' => 64,
      'length' => 2,
      'x' => 37,
      'height' => 0
    },
    {
      'x' => 49,
      'length' => 3,
      'y' => 52,
      'height' => 4
    },
    {
      'y' => 17,
      'length' => 5,
      'x' => 13,
      'height' => 5
    },
    {
      'height' => 3,
      'x' => 9,
      'length' => 4,
      'y' => 38
    },
    {
      'height' => 4,
      'y' => 35,
      'length' => 7,
      'x' => 16
    },
    {
      'height' => 6,
      'y' => 24,
      'length' => 4,
      'x' => 54
    },
    {
      'height' => 9,
      'length' => 0,
      'y' => 15,
      'x' => 32
    },
    {
      'x' => 92,
      'length' => 3,
      'y' => 95,
      'height' => 8
    },
    {
      'length' => 4,
      'y' => 75,
      'x' => 17,
      'height' => 9
    },
    {
      'length' => 1,
      'y' => 57,
      'x' => 61,
      'height' => 2
    },
    {
      'height' => 6,
      'y' => 18,
      'length' => 8,
      'x' => 27
    },
    {
      'length' => 7,
      'x' => 35,
      'y' => 89,
      'height' => 0
    },
    {
      'y' => 99,
      'length' => 9,
      'x' => 57,
      'height' => 5
    },
    {
      'length' => 8,
      'x' => 40,
      'y' => 67,
      'height' => 6
    },
    {
      'height' => 8,
      'length' => 5,
      'x' => 17,
      'y' => 26
    },
    {
      'length' => 0,
      'y' => 29,
      'x' => 23,
      'height' => 9
    },
    {
      'x' => 83,
      'length' => 5,
      'y' => 59,
      'height' => 3
    },
    {
      'height' => 8,
      'length' => 5,
      'x' => 1,
      'y' => 86
    },
    {
      'height' => 9,
      'y' => 61,
      'length' => 7,
      'x' => 98
    },
    {
      'height' => 1,
      'y' => 10,
      'length' => 5,
      'x' => 22
    },
    {
      'height' => 6,
      'y' => 25,
      'length' => 0,
      'x' => 80
    },
    {
      'height' => 8,
      'length' => 0,
      'y' => 23,
      'x' => 34
    },
    {
      'height' => 0,
      'x' => 91,
      'length' => 2,
      'y' => 46
    },
    {
      'y' => 0,
      'length' => 0,
      'x' => 61,
      'height' => 9
    },
    {
      'y' => 59,
      'length' => 0,
      'x' => 4,
      'height' => 1
    },
    {
      'x' => 36,
      'length' => 7,
      'y' => 47,
      'height' => 1
    },
    {
      'height' => 1,
      'y' => 47,
      'length' => 7,
      'x' => 95
    },
    {
      'x' => 97,
      'length' => 8,
      'y' => 55,
      'height' => 9
    },
    {
      'length' => 8,
      'y' => 31,
      'x' => 15,
      'height' => 5
    },
    {
      'x' => 96,
      'length' => 3,
      'y' => 34,
      'height' => 1
    },
    {
      'height' => 7,
      'length' => 4,
      'x' => 96,
      'y' => 89
    },
    {
      'x' => 34,
      'length' => 8,
      'y' => 39,
      'height' => 1
    },
    {
      'height' => 6,
      'y' => 33,
      'length' => 4,
      'x' => 54
    },
    {
      'x' => 25,
      'length' => 9,
      'y' => 48,
      'height' => 6
    },
    {
      'y' => 60,
      'length' => 1,
      'x' => 11,
      'height' => 3
    },
    {
      'height' => 0,
      'x' => 38,
      'length' => 1,
      'y' => 18
    },
    {
      'height' => 1,
      'y' => 99,
      'length' => 1,
      'x' => 82
    },
    {
      'y' => 57,
      'length' => 2,
      'x' => 74,
      'height' => 7
    },
    {
      'length' => 2,
      'y' => 73,
      'x' => 73,
      'height' => 3
    },
    {
      'x' => 29,
      'length' => 1,
      'y' => 54,
      'height' => 4
    },
    {
      'height' => 7,
      'length' => 9,
      'y' => 16,
      'x' => 70
    },
    {
      'height' => 8,
      'length' => 5,
      'y' => 7,
      'x' => 72
    },
    {
      'height' => 6,
      'y' => 49,
      'length' => 8,
      'x' => 85
    },
    {
      'height' => 1,
      'length' => 0,
      'x' => 89,
      'y' => 18
    },
    {
      'height' => 3,
      'y' => 11,
      'length' => 4,
      'x' => 6
    },
    {
      'length' => 8,
      'x' => 66,
      'y' => 96,
      'height' => 3
    },
    {
      'length' => 1,
      'x' => 3,
      'y' => 36,
      'height' => 4
    },
    {
      'height' => 3,
      'length' => 4,
      'y' => 96,
      'x' => 89
    },
    {
      'height' => 5,
      'x' => 72,
      'length' => 8,
      'y' => 34
    },
    {
      'length' => 0,
      'x' => 63,
      'y' => 30,
      'height' => 3
    },
    {
      'y' => 86,
      'length' => 1,
      'x' => 24,
      'height' => 6
    },
    {
      'height' => 6,
      'y' => 63,
      'length' => 6,
      'x' => 18
    },
    {
      'height' => 1,
      'y' => 68,
      'length' => 2,
      'x' => 96
    },
    {
      'height' => 5,
      'length' => 6,
      'y' => 40,
      'x' => 90
    },
    {
      'height' => 5,
      'x' => 86,
      'length' => 2,
      'y' => 46
    },
    {
      'height' => 1,
      'y' => 36,
      'length' => 1,
      'x' => 95
    },
    {
      'y' => 44,
      'length' => 6,
      'x' => 78,
      'height' => 4
    },
    {
      'x' => 33,
      'length' => 4,
      'y' => 10,
      'height' => 8
    },
    {
      'y' => 45,
      'length' => 6,
      'x' => 6,
      'height' => 6
    },
    {
      'height' => 8,
      'x' => 70,
      'length' => 0,
      'y' => 49
    },
    {
      'length' => 0,
      'y' => 46,
      'x' => 61,
      'height' => 5
    },
    {
      'height' => 3,
      'x' => 16,
      'length' => 3,
      'y' => 34
    },
    {
      'height' => 7,
      'length' => 1,
      'x' => 17,
      'y' => 67
    },
    {
      'x' => 59,
      'length' => 9,
      'y' => 98,
      'height' => 4
    },
    {
      'height' => 0,
      'y' => 23,
      'length' => 1,
      'x' => 75
    },
    {
      'x' => 24,
      'length' => 3,
      'y' => 94,
      'height' => 0
    },
    {
      'y' => 60,
      'length' => 3,
      'x' => 82,
      'height' => 3
    },
    {
      'height' => 4,
      'x' => 67,
      'length' => 5,
      'y' => 44
    },
    {
      'height' => 6,
      'y' => 48,
      'length' => 8,
      'x' => 96
    },
    {
      'height' => 3,
      'y' => 51,
      'length' => 1,
      'x' => 3
    },
    {
      'height' => 1,
      'length' => 4,
      'y' => 18,
      'x' => 88
    },
    {
      'x' => 90,
      'length' => 7,
      'y' => 96,
      'height' => 6
    },
    {
      'length' => 1,
      'y' => 87,
      'x' => 85,
      'height' => 6
    },
    {
      'height' => 2,
      'length' => 9,
      'y' => 67,
      'x' => 65
    },
    {
      'height' => 0,
      'y' => 12,
      'length' => 3,
      'x' => 52
    },
    {
      'height' => 3,
      'length' => 5,
      'x' => 5,
      'y' => 90
    },
    {
      'height' => 2,
      'y' => 83,
      'length' => 9,
      'x' => 0
    },
    {
      'height' => 7,
      'length' => 0,
      'x' => 95,
      'y' => 10
    },
    {
      'length' => 9,
      'x' => 93,
      'y' => 95,
      'height' => 1
    },
    {
      'length' => 6,
      'y' => 34,
      'x' => 84,
      'height' => 5
    },
    {
      'x' => 96,
      'length' => 9,
      'y' => 52,
      'height' => 0
    },
    {
      'height' => 0,
      'length' => 5,
      'x' => 42,
      'y' => 11
    },
    {
      'height' => 2,
      'y' => 81,
      'length' => 9,
      'x' => 52
    },
    {
      'y' => 6,
      'length' => 8,
      'x' => 95,
      'height' => 1
    },
    {
      'height' => 4,
      'y' => 44,
      'length' => 4,
      'x' => 66
    },
    {
      'length' => 4,
      'y' => 78,
      'x' => 25,
      'height' => 9
    },
    {
      'height' => 1,
      'x' => 64,
      'length' => 3,
      'y' => 77
    },
    {
      'y' => 5,
      'length' => 3,
      'x' => 78,
      'height' => 5
    },
    {
      'y' => 29,
      'length' => 9,
      'x' => 79,
      'height' => 4
    },
    {
      'height' => 8,
      'x' => 4,
      'length' => 0,
      'y' => 75
    },
    {
      'y' => 31,
      'length' => 6,
      'x' => 8,
      'height' => 3
    },
    {
      'height' => 4,
      'x' => 0,
      'length' => 7,
      'y' => 4
    },
    {
      'height' => 1,
      'length' => 6,
      'y' => 10,
      'x' => 6
    },
    {
      'x' => 80,
      'length' => 2,
      'y' => 29,
      'height' => 9
    },
    {
      'length' => 3,
      'x' => 99,
      'y' => 99,
      'height' => 0
    },
    {
      'x' => 32,
      'length' => 9,
      'y' => 50,
      'height' => 4
    },
    {
      'y' => 62,
      'length' => 6,
      'x' => 71,
      'height' => 1
    },
    {
      'height' => 7,
      'x' => 44,
      'length' => 1,
      'y' => 24
    },
    {
      'y' => 72,
      'length' => 7,
      'x' => 97,
      'height' => 5
    },
    {
      'height' => 4,
      'x' => 14,
      'length' => 3,
      'y' => 3
    },
    {
      'height' => 5,
      'y' => 52,
      'length' => 5,
      'x' => 42
    },
    {
      'y' => 88,
      'length' => 1,
      'x' => 68,
      'height' => 9
    },
    {
      'height' => 8,
      'length' => 1,
      'y' => 8,
      'x' => 31
    },
    {
      'x' => 77,
      'length' => 8,
      'y' => 26,
      'height' => 8
    },
    {
      'length' => 8,
      'y' => 99,
      'x' => 51,
      'height' => 2
    },
    {
      'length' => 6,
      'y' => 96,
      'x' => 20,
      'height' => 8
    },
    {
      'y' => 42,
      'length' => 9,
      'x' => 84,
      'height' => 0
    },
    {
      'length' => 0,
      'x' => 49,
      'y' => 58,
      'height' => 7
    },
    {
      'y' => 66,
      'length' => 9,
      'x' => 30,
      'height' => 7
    },
    {
      'height' => 0,
      'length' => 9,
      'x' => 48,
      'y' => 22
    },
    {
      'length' => 9,
      'x' => 82,
      'y' => 90,
      'height' => 7
    },
    {
      'height' => 1,
      'length' => 2,
      'y' => 27,
      'x' => 84
    },
    {
      'height' => 5,
      'x' => 71,
      'length' => 7,
      'y' => 6
    },
    {
      'length' => 2,
      'x' => 56,
      'y' => 37,
      'height' => 5
    },
    {
      'height' => 9,
      'y' => 66,
      'length' => 3,
      'x' => 66
    },
    {
      'y' => 89,
      'length' => 6,
      'x' => 51,
      'height' => 1
    },
    {
      'y' => 94,
      'length' => 1,
      'x' => 66,
      'height' => 8
    },
    {
      'height' => 9,
      'length' => 6,
      'y' => 24,
      'x' => 71
    },
    {
      'height' => 0,
      'x' => 63,
      'length' => 2,
      'y' => 75
    },
    {
      'y' => 13,
      'length' => 9,
      'x' => 6,
      'height' => 6
    },
    {
      'height' => 1,
      'y' => 12,
      'length' => 8,
      'x' => 88
    },
    {
      'height' => 7,
      'x' => 77,
      'length' => 6,
      'y' => 52
    },
    {
      'y' => 43,
      'length' => 1,
      'x' => 78,
      'height' => 0
    },
    {
      'height' => 3,
      'x' => 23,
      'length' => 3,
      'y' => 25
    }
);
my $OBJECT_COUNT = scalar @OBJECT_DEFINITIONS;


my $collide = Game::Collisions->new;
my @objects = map { $collide->make_aabb( $_ ) } @OBJECT_DEFINITIONS;

say "Running tree-based benchmark";
run_bench( "get_collisions_for_aabb" );
say "";
say "Running brute force benchmark";
run_bench( "get_collisions_for_aabb_bruteforce" );


sub run_bench
{
    my ($call) = @_;
    my $start = [gettimeofday()];
    $collide->$call( $objects[0] )
        for 1 .. ITERATION_COUNT;
    my $elapsed = tv_interval( $start );

    my $checks_per_sec = (ITERATION_COUNT * $OBJECT_COUNT) / $elapsed;
    my $checks_per_frame = $checks_per_sec / FPS;
    say "    Ran $OBJECT_COUNT objects " . ITERATION_COUNT . " times in $elapsed sec";
    say "    $checks_per_sec objects/sec";
    say "    $checks_per_frame per frame @" . FPS . " fps";
}
