#!/usr/bin/perl -w

use strict;

use Test::More tests => 29;

use lib "t/lib";
use Test::FloatNear;

BEGIN {
	if ($] >= 5.006){
		require Fcntl; Fcntl->import(qw/SEEK_SET/);
	} else {
		require POSIX; POSIX->import(qw/SEEK_SET/);
	}
}

BEGIN { use_ok("MPEG::Audio::Frame") }

{
	isa_ok(my $frame = MPEG::Audio::Frame->read(\*DATA), "MPEG::Audio::Frame");
	ok(!$frame->has_crc, "no crc in frame");
	ok(!$frame->broken, "crc check returns true if no crc");
	is($frame->bitrate, 128, "bitrate");
	is($frame->sample, 44100, "sample rate");
	is_near($frame->seconds, 0.0261, "duration");
	is($frame->length, 418, "calculated byte length");
	is(length("$frame"), $frame->length, "actual byte length");

	seek DATA, $frame->offset, SEEK_SET;
	read DATA, my $data, $frame->length;
	is($data, $frame->asbin, "asbin returns data from handle");
}

{ # a different frame
	isa_ok(my $frame = MPEG::Audio::Frame->read(\*DATA), "MPEG::Audio::Frame");
	ok($frame->has_crc, "frame has CRC");
	ok(!$frame->broken, "CRC is good");
	is($frame->bitrate, 224, "bitrate");
	is($frame->sample, 44100, "sample rate");
	is_near($frame->seconds, 0.0261, "duration");
	is($frame->length, 731, "calculated byte length");
	is(length("$frame"), $frame->length, "actual byte length");

	seek DATA, $frame->offset, SEEK_SET;
	read DATA, my $data, $frame->length;
	is($data, "$frame", "asbin through overload returns data from handle");
}

{ # yet another
	isa_ok(my $frame = MPEG::Audio::Frame->read(\*DATA), "MPEG::Audio::Frame");
	ok(!$frame->has_crc, "frame has no CRC");
	ok(!$frame->broken, "crc check returns true if no crc");
	is($frame->bitrate, 320, "bitrate");
	is($frame->sample, 44100, "sample rate");
	is(int($frame->seconds()*10000), 261, "duration");
	is($frame->length, 1045, "calculated byte length");
	is(length("$frame"), $frame->length, "actual byte length");

	seek DATA, $frame->offset, SEEK_SET;
	read DATA, my $data, $frame->length;
	is($data, "$frame", "asbin through overload returns data from handle");
}

ok(!MPEG::Audio::Frame->read(\*DATA), "no mpeg audio left in DATA");

__DATA__
the following data is used to test the module.

and mp3 header and frame will follow this (text|garbage)
and will be parsed and munged and whatever.

here goes nothing...



���@     7�     �      �      �                                                                                                                                                                                                                                                                                                                                                                                                 



this is more garbage to be ignored


dgskjhag
�����  ɊH&N  ��H��H e�"=� 
j��K��    �c�� :#f;+\��o >���5g��bq�O�
P(�%1s��������?��&.A�"69�O����'l��������y+�a*r.W"�S����"��P�hO�f������������P�r.nE��|�n\.x
Si���*��o�G�@0 ��<N���o |� �Y�8�� �	L\���1da8�ȟ��,��"�9 � ���,��"c0A
��@Ș������x����6A��r�����������ό�7 �Pо_7�p�0�0�
�D�=1s��A%Yh���R���O���A0�=A��E$�����afbI%EM$��ffk�RUUz���U�j��[�<L�)��}JU��}k�o<��Գ��ZC#��3[G�����2��.lӠ�5�5Ts��eC��4�VUo��khY�4u0�L<
(�F�h"���̰T�B��8�ӵ����T�4�S�S3�����C��̔�5Egh������&ٗ.
��|pю�u-�:��[^���R�ߨ�Mm���e$���MTP���
�y
:�~]��9�&oR�L�P�FP6��]���A>etMC#��=3�L�sBphq��\�`�YF
	��0��Ѐ��sh>���!h��BY�t��4b�����`Y�(nQ�&<����

dgk���uwj more �ʬĩϫgarbage&&$Y n4bn�oet
a�Ӳ�y�c���o����17�*�T1�F�Il��Ɵ9�;W�j����.~���I$K?8��_����n�H�փ,�3P�������Z~�\x,�%+���̎�yb�� <�����G	 ͐> \H�IDFG������*|'GI�Ѹ���U������9��0Fr�cUNt�
��������7Z������G�swc�uퟹ}٤�ɵ��O��ڟX�d x�b�2�",y�8n	�j�LgXc �f��a����ų� �� �?2�Mj�@�� �6z���iD�3ȍ��î5/�V��d�'�V3c
�49�(\�	�3H����'`�!#4%˜�
ĚŦ	�D2Xڐ5JLi�b��i�.rDJ� �f�Md���  �3DH Pū@k!A؊�%\�i��8T}An�h�� <P�����bϴU��MJ2���8.ܧ��!�����dЧg�)T��h]����V�'��n�[Yܡ�x��ɸ���5�jh~��lK�n_?7jk-�[�U)j��-�������6�f�n�Un4F|�T�_��jR�� ��/��>L!�O��w�?O����|���"�(���q�Z�Ml��%^r�
veru���j�rȨ_�	�i> �y6@�ҰI&*|��$�I ly���L��V�ۭyՖ��P��;wqU���%M��]���nJ^�Q�^��C�)F)ou��*��                                                                                                                                                ���`  |aN��p�j� a�ne͇4�-�H��I�%y4k�:l�1hG1��24�0��0�	�-�$,� ,.� &��)�(&0T�ʁG"�H������k-����Qp����-�@*(4W/�0
�)3M牫��T��%�{�ol�MQ��"y��op�7��X7���q�{�xa-��A�?&f�YQ�6���@ o��($:�P�o6�JC����<��cY�M^�������]?�����WT;~e�b!�a�%ߡ�ё��:�J�:���}��v"���D�0� .�A�������b�PQxao��G�PZmH)"*�4@q��X���`  
��O�V` ��
tƜ $U�>��Z/(Þ� ��M����G0�C�$�A�B�8�hA2$)31a�,/��˕Đv�r`H� "(�B!�`б 4d�# ���p<��,�.�b0n�����EJ��!������!��0`Y)��Ь�D�@�}���B( lx:p1R�1�� $��	Qy|���t�\�b~"�6&��I(�Q�-��k��D1�E2��	H�t�_D�h:�i��DШ]iD�I���i ��x[ƨ̊Q�YlԐ,����}_��QuN����E(��_��     %��Fpa��R����y�7/��Tp�务�YI�(F6vaᒧ�d��b�.YtS<�%S
�����gR,q%B.���24y7K!��lx��0T�����}h���gfy��)�4٩oNy�8��c������������
�y3�@�c�Ɍ%����H}�{x�[���A�.o&e��,>��뾔���j˽tF��N" �p��� �P�aZ�l�����u�f\�|��<Tc�5�b@����S��J"H�%�48��&�3e�D1�+J^IP�&�:Q%�0���d��.�[`r�A�Rv�	���:
���t��i	�n��SW���Pen�"t��;0�'��D����}�K!���}��K���)1�ߤ���G�;�=�%�5�����v��nQv�5��o-��e�7u�R� �Z*�U~6�+"������w�/G���mz
~^r�3�����d����q`'d�c�L."T�Ĳ�c�"F �B����ڷ�/Z�yX@-�H5���u���y{mA~��}��E�g��b�of��X?�/��ٳ[�}��������>*�Y-�                                                                                                                                                ���`  �[�I�crEf��$#\�{c��-��p�q�� ��H�=P���G*X+�x:��M�8��_��c{���m��xP��:ʌ���$�:��9,r0XlrdF*�JD/8=<H���"������/֌��|]��#k�oYg��Alk���'���]�/n��*nOR���-��6���9��0�t $'   _MrE�)�N�����FA���z+�de0k���o��7"�
