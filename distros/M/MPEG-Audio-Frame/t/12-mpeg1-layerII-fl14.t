#!/usr/bin/perl -w
# based on fl14.mpg
# http://bmrc.berkeley.edu/ftp/pub/multimedia/mpeg/mpeg2/conformance-bitstreams/audio/mpeg1/compliance/

use strict;
use integer;

my $n;
use Test::More tests => ($n = 16) * 8 + 2;
BEGIN { use_ok("MPEG::Audio::Frame") };

for (1 .. $n){
	isa_ok(my $frame = MPEG::Audio::Frame->read(*DATA), "MPEG::Audio::Frame", "frame $_");
	ok($frame->mpeg1, "frame is MPEG1");
	ok($frame->layer2, "frame is layer II");
	ok($frame->has_crc, "frame has crc");
	ok(!$frame->broken, "frame isn't broken");
	is($frame->bitrate, 384, "bitrate");
	is($frame->sample, 48000, "sample rate");
	ok($frame->dual_channel, "dual_channel");
}
is(MPEG::Audio::Frame->read(*DATA), undef, "nothing else in the file");

__DATA__
���)e��ivvvvwwgw�m��k�(   �#       	P�~�w6-�J��QJ8>N��ԫ�{:R�Y��n��Z͛�����|b�\Ϧp���j���Ʋ��=o�����>s���3�|w=���<w?_� �� �?�� ���������}�������}�{�����}��}��}�{�����{����{����{����{����{���{�kc_6	��7����=op.�`D���A�|��������/t�ǡq�]z^���P;��9�s����t�=�{��9�s������A��5�M���G�iAW3< r�H"t�\
�4�t�s�����Z�� R�U,��D��<T��'Ͷl�'����;dv�l$�(�N�H�N���
�v�8)Cpc<]�M������t!מ\^ۏ5φ!���u�^y�^qס�CP��=�{��9������=�{��9��=��5�{��a���1%�n���4�A�	�fc0����݇4���� &�Y�{�wY��2s<+wp
���ڇk.Q�L��O��Ӵ�܏'ƖF ?��^����߿�t��f��=�}����{�~\u�_�'��<��>��ta��s�������s������5���|idap��1%�n� �����A�}��o���ށ�{�<����u�^��"~/sϾ�����k^�F{�9�{a=�|_=�|��[�-�7ƖF ?��^����߿�t��f��=�}����{�~\u�_�'��<��>��ta��s�������s������5���|idax4u1%�n)�ܺ��A�AP�q��"
�ŷ�j�±'n4H��y��(�\#��	0�pn[i��}hk�Hco]�5�WMEK�J�]�ƖF�A�S^���]˯�tg�r �[z6���+v�@$�\�����E�?ޠP��嶟>:ֆ�Ć6��[5t�T���E�p�idax4u1%�n)�ܺ��A�AP�q��"
�ŷ�j�±'n4H��y��(�\#��	0�pn[i��}hk�Hco]�5�WMEK�J�]�ƖF�A�S^���]˯�tg�r �[z6���+v�@$�\�����E�?ޠP��嶟>:ֆ�Ć6��[5t�T���E�p��������z���ewcf�ۥ�$�     ����������>}��N:�ν�����=�޾��|�߾��7��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h���6���^��R(.Ż��~vB�GTig���5�*�e�N-.��˖��Q(����&~cDָ9��������͹R<+�����YF���X��ֻ�E�طx/��hRꀂ��,�;��[l��ť�0"9r�c�%��Q7D��h��3<��1�q��ٷ jG�uӖ5��vK(�`pPc��z�qH������M
�APT9��G`����m�u8���G.[�~QD�t
�&���Z��g�s�6c�4[6�H�rƴ_��e
�ubz/Z�)b��\�;	�H#�
��4�����m�Χ�X����y��(�O�D�?1�k\���|��yƃ�f܁��NX֋��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h� �������z���ewcf�ۥ�$�     ����������>}��N:�ν�����=�޾��|�߾��7��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h���6���^��R(.Ż��~vB�GTig���5�*�e�N-.��˖��Q(����&~cDָ9��������͹R<+�����YF���X��ֻ�E�طx/��hRꀂ��,�;��[l��ť�0"9r�c�%��Q7D��h��3<��1�q��ٷ jG�uӖ5��vK(�`pPc��z�qH������M
�APT9��G`����m�u8���G.[�~QD�t
�&���Z��g�s�6c�4[6�H�rƴ_��e
�ubz/Z�)b��\�;	�H#�
��4�����m�Χ�X����y��(�O�D�?1�k\���|��yƃ�f܁��NX֋��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h� �������z���ewcf�ۥ�$�     ����������>}��N:�ν�����=�޾��|�߾��7��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h���6���^��R(.Ż��~vB�GTig���5�*�e�N-.��˖��Q(����&~cDָ9��������͹R<+�����YF���X��ֻ�E�طx/��hRꀂ��,�;��[l��ť�0"9r�c�%��Q7D��h��3<��1�q��ٷ jG�uӖ5��vK(�`pPc��z�qH������M
�APT9��G`����m�u8���G.[�~QD�t
�&���Z��g�s�6c�4[6�H�rƴ_��e
�ubz/Z�)b��\�;	�H#�
��4�����m�Χ�X����y��(�O�D�?1�k\���|��yƃ�f܁��NX֋��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h� �������z���ewcf�ۥ�$�     ����������>}��N:�ν�����=�޾��|�߾��7��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h���6���^��R(.Ż��~vB�GTig���5�*�e�N-.��˖��Q(����&~cDָ9��������͹R<+�����YF���X��ֻ�E�طx/��hRꀂ��,�;��[l��ť�0"9r�c�%��Q7D��h��3<��1�q��ٷ jG�uӖ5��vK(�`pPc��z�qH������M
�APT9��G`����m�u8���G.[�~QD�t
�&���Z��g�s�6c�4[6�H�rƴ_��e
�ubz/Z�)b��\�;	�H#�
��4�����m�Χ�X����y��(�O�D�?1�k\���|��yƃ�f܁��NX֋��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h� �������z���ewcf�ۥ�$�     ����������>}��N:�ν�����=�޾��|�߾��7��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h���6���^��R(.Ż��~vB�GTig���5�*�e�N-.��˖��Q(����&~cDָ9��������͹R<+�����YF���X��ֻ�E�طx/��hRꀂ��,�;��[l��ť�0"9r�c�%��Q7D��h��3<��1�q��ٷ jG�uӖ5��vK(�`pPc��z�qH������M
�APT9��G`����m�u8���G.[�~QD�t
�&���Z��g�s�6c�4[6�H�rƴ_��e
�ubz/Z�)b��\�;	�H#�
��4�����m�Χ�X����y��(�O�D�?1�k\���|��yƃ�f܁��NX֋��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h� �������z���ewcf�ۥ�$�     ����������>}��N:�ν�����=�޾��|�߾��7��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h���6���^��R(.Ż��~vB�GTig���5�*�e�N-.��˖��Q(����&~cDָ9��������͹R<+�����YF���X��ֻ�E�طx/��hRꀂ��,�;��[l��ť�0"9r�c�%��Q7D��h��3<��1�q��ٷ jG�uӖ5��vK(�`pPc��z�qH������M
�APT9��G`����m�u8���G.[�~QD�t
�&���Z��g�s�6c�4[6�H�rƴ_��e
�ubz/Z�)b��\�;	�H#�
��4�����m�Χ�X����y��(�O�D�?1�k\���|��yƃ�f܁��NX֋��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h� �������z���ewcf�ۥ�$�     ����������>}��N:�ν�����=�޾��|�߾��7��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h���6���^��R(.Ż��~vB�GTig���5�*�e�N-.��˖��Q(����&~cDָ9��������͹R<+�����YF���X��ֻ�E�طx/��hRꀂ��,�;��[l��ť�0"9r�c�%��Q7D��h��3<��1�q��ٷ jG�uӖ5��vK(�`pPc��z�qH������M
�APT9��G`����m�u8���G.[�~QD�t
�&���Z��g�s�6c�4[6�H�rƴ_��e
�ubz/Z�)b��\�;	�H#�
��4�����m�Χ�X����y��(�O�D�?1�k\���|��yƃ�f܁��NX֋��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h� �������z���ewcf�ۥ�$�     ����������>}��N:�ν�����=�޾��|�߾��7��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h���6���^��R(.Ż��~vB�GTig���5�*�e�N-.��˖��Q(����&~cDָ9��������͹R<+�����YF���X��ֻ�E�طx/��hRꀂ��,�;��[l��ť�0"9r�c�%��Q7D��h��3<��1�q��ٷ jG�uӖ5��vK(�`pPc��z�qH������M
�APT9��G`����m�u8���G.[�~QD�t
�&���Z��g�s�6c�4[6�H�rƴ_��e
�ubz/Z�)b��\�;	�H#�
��4�����m�Χ�X����y��(�O�D�?1�k\���|��yƃ�f܁��NX֋��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h� �������z���ewcf�ۥ�$�     ����������>}��N:�ν�����=�޾��|�߾��7��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h���6���^��R(.Ż��~vB�GTig���5�*�e�N-.��˖��Q(����&~cDָ9��������͹R<+�����YF���X��ֻ�E�طx/��hRꀂ��,�;��[l��ť�0"9r�c�%��Q7D��h��3<��1�q��ٷ jG�uӖ5��vK(�`pPc��z�qH������M
�APT9��G`����m�u8���G.[�~QD�t
�&���Z��g�s�6c�4[6�H�rƴ_��e
�ubz/Z�)b��\�;	�H#�
��4�����m�Χ�X����y��(�O�D�?1�k\���|��yƃ�f܁��NX֋��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h� �������z���ewcf�ۥ�$�     ����������>}��N:�ν�����=�޾��|�߾��7��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h���6���^��R(.Ż��~vB�GTig���5�*�e�N-.��˖��Q(����&~cDָ9��������͹R<+�����YF���X��ֻ�E�طx/��hRꀂ��,�;��[l��ť�0"9r�c�%��Q7D��h��3<��1�q��ٷ jG�uӖ5��vK(�`pPc��z�qH������M
�APT9��G`����m�u8���G.[�~QD�t
�&���Z��g�s�6c�4[6�H�rƴ_��e
�ubz/Z�)b��\�;	�H#�
��4�����m�Χ�X����y��(�O�D�?1�k\���|��yƃ�f܁��NX֋��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h� �������z���ewcf�ۥ�$�     ����������>}��N:�ν�����=�޾��|�߾��7��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h���6���^��R(.Ż��~vB�GTig���5�*�e�N-.��˖��Q(����&~cDָ9��������͹R<+�����YF���X��ֻ�E�طx/��hRꀂ��,�;��[l��ť�0"9r�c�%��Q7D��h��3<��1�q��ٷ jG�uӖ5��vK(�`pPc��z�qH������M
�APT9��G`����m�u8���G.[�~QD�t
�&���Z��g�s�6c�4[6�H�rƴ_��e
�ubz/Z�)b��\�;	�H#�
��4�����m�Χ�X����y��(�O�D�?1�k\���|��yƃ�f܁��NX֋��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h� �������z���ewcf�ۥ�$�     ����������>}��N:�ν�����=�޾��|�߾��7��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h���6���^��R(.Ż��~vB�GTig���5�*�e�N-.��˖��Q(����&~cDָ9��������͹R<+�����YF���X��ֻ�E�طx/��hRꀂ��,�;��[l��ť�0"9r�c�%��Q7D��h��3<��1�q��ٷ jG�uӖ5��vK(�`pPc��z�qH������M
�APT9��G`����m�u8���G.[�~QD�t
�&���Z��g�s�6c�4[6�H�rƴ_��e
�ubz/Z�)b��\�;	�H#�
��4�����m�Χ�X����y��(�O�D�?1�k\���|��yƃ�f܁��NX֋��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h� �������z���ewcf�ۥ�$�     ����������>}��N:�ν�����=�޾��|�߾��7��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h���6���^��R(.Ż��~vB�GTig���5�*�e�N-.��˖��Q(����&~cDָ9��������͹R<+�����YF���X��ֻ�E�طx/��hRꀂ��,�;��[l��ť�0"9r�c�%��Q7D��h��3<��1�q��ٷ jG�uӖ5��vK(�`pPc��z�qH������M
�APT9��G`����m�u8���G.[�~QD�t
�&���Z��g�s�6c�4[6�H�rƴ_��e
�ubz/Z�)b��\�;	�H#�
��4�����m�Χ�X����y��(�O�D�?1�k\���|��yƃ�f܁��NX֋��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h� �������z���ewcf�ۥ�$�     ����������>}��N:�ν�����=�޾��|�߾��7��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h���6���^��R(.Ż��~vB�GTig���5�*�e�N-.��˖��Q(����&~cDָ9��������͹R<+�����YF���X��ֻ�E�طx/��hRꀂ��,�;��[l��ť�0"9r�c�%��Q7D��h��3<��1�q��ٷ jG�uӖ5��vK(�`pPc��z�qH������M
�APT9��G`����m�u8���G.[�~QD�t
�&���Z��g�s�6c�4[6�H�rƴ_��e
�ubz/Z�)b��\�;	�H#�
��4�����m�Χ�X����y��(�O�D�?1�k\���|��yƃ�f܁��NX֋��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h� �������z���ewcf�ۥ�$�     ����������>}��N:�ν�����=�޾��|�߾��7��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h���6���^��R(.Ż��~vB�GTig���5�*�e�N-.��˖��Q(����&~cDָ9��������͹R<+�����YF���X��ֻ�E�طx/��hRꀂ��,�;��[l��ť�0"9r�c�%��Q7D��h��3<��1�q��ٷ jG�uӖ5��vK(�`pPc��z�qH������M
�APT9��G`����m�u8���G.[�~QD�t
�&���Z��g�s�6c�4[6�H�rƴ_��e
�ubz/Z�)b��\�;	�H#�
��4�����m�Χ�X����y��(�O�D�?1�k\���|��yƃ�f܁��NX֋��,�a��A��OE�]�"��l[���a4)u@AP�y��[��Y�����o1�E���(��g�4Mk���]Ϙُ8�}lې5#º���~;%�l08(1Չ�k��P\�w�r��&� ��*��#�?�k`U��:�Z]c#�-�?(�Q?�tL�Ɖ�ps3˹�1���r�xW]9cZ/�d���:�=�w���n�._��Ф�C�Y�v�l
���gS�K�`Dr���J'�@�n����5�fyw>cf<�A��n@ԏ
��,kE��Q����V'����Ap6-����:� �sK<������V�,�qiu��\�����D��M�3�&����.��lǜh>�m���]t�h� 
