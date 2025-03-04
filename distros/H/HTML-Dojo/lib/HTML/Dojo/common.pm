package HTML::Dojo::common;
1;
__DATA__
__CPAN_COMMON__ iframe_history.html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
	<title></title>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8"></meta>
	<script type="text/javascript">
	// <!--
	var noInit = false;
	var domain = "";
	// document.domain = "localhost";
	
	function defineParams(sparams){
		if(sparams){
			var ss = (sparams.indexOf("&amp;") >= 0) ? "&amp;" : "&";
			sparams = sparams.split(ss);
			for(var x=0; x<sparams.length; x++){
				var tp = sparams[x].split("=");
				if(typeof window[tp[0]] != "undefined"){
					window[tp[0]] = ((tp[1]=="true")||(tp[1]=="false")) ? eval(tp[1]) : tp[1];
				}
			}
		}
	}
	
	function init(){
		// parse the query string if there is one to try to get params that
		// we can act on. Also allow params to be in a fragment identifier.
		var query = null;
		var frag = null;
		var url = document.location.href;
		var hashIndex = url.indexOf("#");
		
		//Extract fragment identifier
		if(hashIndex != -1){
			frag = url.substring(hashIndex + 1, url.length);
			url = url.substring(0, hashIndex);
		}

		//Extract querystring
		var parts = url.split("?");
		if(parts.length == 2){
			query = parts[1];
		}

		defineParams(query);
		defineParams(frag);

		if(noInit){ return; }
		if(domain.length > 0){
			document.domain = domain;
		}
		var hasParentDojo = false;
		try{
			hasParentDojo = window.parent != window && window.parent["dojo"];
		}catch(e){
			alert("Initializing iframe_history.html failed. If you are using a cross-domain Dojo build,"
				+ " please save iframe_history.html to your domain and set djConfig.dojoIframeHistoryUrl"
				+ " to the path on your domain to iframe_history.html");
			throw e;
		}

		if(hasParentDojo){
			//Set the page title so IE history shows up with a somewhat correct name.
			document.title = window.parent.document.title;
			
			//Notify parent that we are loaded.
			var pdj = window.parent.dojo;
			if(pdj["undo"] && pdj["undo"]["browser"]){
				pdj.undo.browser.iframeLoaded(null, window.location);
			}
		}

	}
	// -->
	</script>
</head>
<body onload="try{ init(); }catch(e){ alert(e); }">
	<h4>The Dojo Toolkit -- iframe_history.html</h4>

	<p>This file is used in Dojo's back/fwd button management.</p>
</body>
</html>

__CPAN_COMMON__ flash6_gateway.swf
CWS�	  x��VKsE�}H[~E6Vo�b�K&!��������H�5p� ƫ�%��U����#@U��U�9r��D��H��V3ӯ�����.�&�W{0g9Y `�y��߆O�%"
���{��"@��'�)ﻂ7���0�%�8�Q�Z�ɣ��rm@�~½~.��՞��0R}��y#���_��I����A;is����z�	�K����/�{a�Ã�B�D=ԙ:l�_�;"�<��/1h,��7���;���	��{�0�:tD�
U�� � �x�L/�J����y����:"H�I���G縈DҋW�=?�����ԏ�i<4ڷ�w�Y�A??�S������:�y�r{A@�-�OO�3��ty4��(�}���4{����@%;��`�w�~�"i�z6���&�h���v�^�G�	l������O�3�ۋ��t�I���-�v�~�]H.�Sy���"9��.f��L`�d|�R�W�|��EN��H����`f7fYm,��'�Mf;�Z���\I��9�)����:LQB�e�|���cµ	�SFN�Z3�A
4dlv��Е(�L����Y0IVܭI����{�`eY;���O#8�y��1�s�JHْsD�k�$�-�g��`R}j��|.9�L�D(�-R�<���{���C�y�0�Y�ӳ�&�a[�L��:F�u<��b�6Z���6��'�c��چ�T�U~(sۤ�m�6���m�H��aZ�5�`���/�����YZǟa�9(�OT�9@�K=G��KPy��%7kU�C2v[+ܜ��X��&������1� �)y���3\���!̫
� 3V�CH[˪�W2�J�ɯMb+�/m��a]�js��mX.�y}`	�JI���
�1���v=�����7�ufҳLn9�"� K	�H�E;�n��I~�=$�M���mKSs������+//�Y��qJi�V����N
n�m9/i�;�<l�d'�V&�E�c�fE8	��ɢ��ߴ?rC��}��T��~&��T*d��*j��Kzۊ����G��f	
ϗ� wd]0�]Wj��,�t�R�ʵ<F��܉*������_<�Z�r��&���{����E:�a��g��kX}V�'�g��%������
__CPAN_COMMON__ storage_dialog.swf
CWSF~ x��;Yp�u������ ��I�ER$�K�	��$%Z4�`W�݁w`[e�-��eºM%>(ǲ")QR�)��NY�C��R�#UVUR�ʕJ�\Q6����B�;���{��~���9ʹI�N��T���7Y�������1�X�MNN��~�ү{�V8����Ο�cպV�X����d24l ڭ�1��f��by�5Ǟa)���]���~��v����7[�kp� ���e��=o�Z�8�P�Y�bK)�f�9h��ϙb�f��ƨ����(e�-��p5�̛˦��).cȨ�Õ|e���넀���_�����7��M�:!�81�8V�7$`�'`=	8��c+ @����}�T�L������w�SWa��9,l�X�6��$�5[U���T��l��wuU���Z��Q����UmA�H���v�5B��.�[�~�P�3�?�����@�Br������S�:���>��6�Wo��1��ⶐ�7M�ɢ%�o���V�A�y}������2�):���ｷ��#�:0��z���u>�:p�p�H3 ��=��`M �"� &Oc����$Q
%��2q�:$;������4���ƗQ�Ά�I}�tl�\&�i@.c'GF'�5rΑ9�(�E��ݶ ��)�@tO
�9ى����n�FH;�޺���b/��l�_�~�>b��*k��_�l?�����o��p��uն݅i�y�'3���@K�1�˱���I�B!��M`G��Y/�M���Q���
����H�|q��x)G�7��+ذ����(|��0@W�����|P�vf*h%�FY�V��`k����Z��p��ߕ��1��O�H�����WA�U`�A�4m�!�.�z���������.H ��O�}@�:`չ�S����W�Y����1|���7���=Q��z����_��ZY��R�	�����%j�a����)��K} ��<��i�<�����%Lh�`M���g1w��a�3����<t�`�/ �5��!:�-i���0��B�ϭ�HU�_ፘ�L�����ڽXAbMMAb�VcFY�0��٢]�@,4aN���̊^,wcV�mżS���L�^;~��^��jп���nЖ7�5{���`sN1 �� �p�3-[��*�fl�֡!�^�R�͑2<)��b4�~��X��m�b�3�g�a9�4٢��c�'P�;	�t�#>����A6S4���!*�M?��m�k��Dp	&�~by�1G��l#0��f��Gw=�O�@ߏ>�S���ݾ���w��w'^S��p���n5���� �- ?f-ɦ�_����T�{C B��#p�b��>a@h�E� f�^L�qH���ϻ����`#.<{�K��:d����s/���}��{���}�{WN����ö{�N���ܛ���+j2�d���]=պ$�gJo3>�Ǐ�3�0{[in[��m�:Qm~s���G�?d�S�5��X4v�0��Tfr�hOW,�r�v�:[4��46e8�㳤�|pX�[�}r�iL���l�/���e�}���+�� �	���{ s�3�9��9e��� Ά;s�u�퇺<d���uJD͸2NV1�`�|ў֝\��YTK���G�IX&�q;��^d'	��9v��9s��Y���`�O`��C��>�ҽl�̦g�d�#�{�+zɐ$CBZ .���f1�aS�u�}��Fy
U/��9��3�C�9ĩm����Ѣ�0�R��P��oǟ�hȱ�gQ�v�j�0A�=���E�yQ]��NX̄�	�\ŀQ�R���'�9g�h�y6��"� ��$�$���rf��JL�q�\�&�@��m�=_��L�⯣�e�^Řΰ}����Hiڙdy&�%[��!ct��)�yz�^��f�$�3 ޡ�z�D �i����f�X��7S�.�#C$U1����K5��$]e^l
�)�lsщR(_ a��)��x$0��L×��ɡ\r]q�h��,ap݁�����v�A��f�v�b�P��:�)Y.�,�6��xŚ6*�<Xvr�(���t�X�P(���9��"f�ș��$�!�[p��r�^6g8>N)s|��C�J�gUJ��ψZ���(-��^����Rќ�W�<t1��+S��=�b��� gi��g��i���m|z�L���A���0�_�.���" (o	ݍ҄�Vh�
X�[�����5�"�pKa��|!��� Ԏ�̊�H�Rёn�o�Z2*SF(P��
�s�v�ﺽ{)C�,�o|x�zr�D�n�/�s��q�tŘ4*��ms�X��|ލM�u�\dl\��<;4evǜk���t+$�	@n	�)�i_�9Ś ���gt��rjk5!�|����J�kt���ĳi`�bXm>��h�ɑ��H@��袊TA�cu�C�2�W�5������5_������+��]�f�[F�ud�!shٛ$��ĝ9L���G�^h����)��we[�ʶr�{���R`�l1IhU�U���,4P:+���3o7��S1�ke�٫��iA�UC�nW�5�YW�nO����u�������[��Ǔ徭,�@8�Բ�k��H�k3|u�l-��j"�;Q!m���{=M����J��Ջ	FR��gCV��1Qk]�l��cW��	TI�<�����S�/�v���?�n��f�)Ȯ�c�%�n��n��n�e�5�n���څ64�
$X�ơ=-�n�,��j[l!��v Wm��hשq��߬�i���h���dd��Q��(|M��{����਑ ۗMK� +��K
����ŅO!�[�@#tJ�Yqm�\Y��W�v��E3�I�*��!4��}z,!��:�JG�M@�]�Z7��G�r��}��Nu�9����%&MzTK2\UT�|���4Թ?s��*#�s+N�Em�=����u���`p��N;x��w��z���u��iXϘ��Rs,9�2!��.<Db��RMjj����Ib��)�Q�3���i�)֠'�,K<	*B����lG�84�+�� h�a��n�n�8�	U[��P<�b<j�HB$��[V��M����v@r��s;�:��}�	Rk\�[)�$!!G9D]A� D~la5��}G"O�$�vv?g�;<�\�EM �$�y@�{.W��p%��3�����>���2�#	�?P���0��Ө��I�0� Y56JC�汅>��[<�RZ�	{�qg�9�c�K�9Ք�9�p�֓����m��'��$%>��W��&�G�׊%U�n#CA��G���35	$�� "�Hc�6U��&1�m�Y�1� ���er%�\��$�<�S>·?�Z���8!R}�{�=�g���D�ݑ�/7�ܣ�|z�P��iw����ߍ�)��F��&�穢�g�C�#�5�_N	}�I.Ԏ>�ZD2��T*�[X�gNL�nq�$�ͣ��0{���^L�d^uo��&�~b���;��e+[�iG�r�\�K�
\p[e�����d���D�NKKx*�����2\W�CŬH�g`�D��EaTӳH�J���Rd���#K�"�T�,G�1��>Z
��R�K��Ҿ��J0x�Ÿ\�o�/����΢ �Q�3"9�r�4��xُ�]���@�-9�^�X.3������b�������e�T�Z�����K�.Wr�:�˕�L��[�3Ku�{B��fH�@B�$t1Ȝ4��<�)lF=�:��D�ϳ>1?@ �%�駭����;�*GŞ�V��y*����;)�_h�<ـ�`����3������} Yi$���tQ���Ŝ'q�s��`�����Z�¢���$�z��Y���3Ly@�`�����2֓�5�>V��R��D�zI�6���Ɠ9�,�y-��N��e�o)9ʱ"D�9����H�OP���X��D���!��5���Ob��ՅT�jQP})D�h�G��A���c>�>�Ǹ�G�v���J�v�킏�C�i�>QC�'H�7Փ!��jP=ET�TO���ZCί���C�k�x�F�w�v3��	2Lb�/����8��8�l�4W����"u󬗈�N�J�vVr�d�:�@��d�N�\�pe:��sء�����dYa#�9K3u�w����%ZTY@,[R�5Q��(�gBg�L�P�4Q�I�yXk����Y���n}s��	f���S1�9Z�؈���i��U����gT��~�/�TH��?�rn�r��!>�x1���O����Þ��d�z���e;,7���+	�T��F�_¿���P}C��+���TJ�JI�g�M�UZIu�(O��z ��@tS�J���\K��tn�HEH񜢞)ѳ�ا@��L|����6z�%��٣�d����t/�Y��ySb	�&<����㷞��g�e4{���y�����0ċ�����i/c4`3S,�f{x�X���FG
���4�7T>��i'[KMo�����[�o�.����v�[��;~\9�;��÷o������߷��~���osn������|�?^��h@~%�	�.�`&���W����	�Y�H�����Z|�XE��at�@���Z��	�z��A�G�7��m���o�b�B��So�	��Z��;j��	����m�~�7�Ə�"'𛤳����x�CB�k>�!^����~��ր����7}������O�n�җ{�;ޭ�9w�����<b�T�=߷v�Q K��������Ңo�';�O����!d�o-���c�.��tv�;������^��qB�r�	�c�Ǥz>�C�#e61�vǫ��ނ�n�}��e�7^i��k��ro�q���n�Q��s��ݧp���?4j9�2�#��Ϣ��֧ts�N�8��F�{-�O�gƜ���I��U)N��ʅS0J�{��}��.�D �?��H��������g|5WV���W�X����ި~dr���<�V��_u\��k�_A�U,>��ɡ=|T���&5.��A!��x�f�y�$�5f����Gئ�yV��][H����@!�Ŀ,����AL�+OO��c�ݳ�2�T[� >ڻp͟�42��z�~��a;\+uPE���w<���?����kEq�)�&j�4��A�?��k�x�«p0(��tj�����'X���:�uiݑ_���%�v��J�7�Qd��XWEƺJ��vɱ��Z�E󭓛�Ek��ғg=���lf1w~�:Z�L�|�p�6�������Jm��
�DH�$����J8�����=x���nʈ�W�<��J�UK�7��l�d��ayM�X�s<l{�W����_A{�7}��h�����G�S}%(�{� zS����3�\�����\Ey�?g}�ނ��D{�������Bl�X�z2�?
P�ZѠ3����a����)'�u2�����[Y`�5���Zh�
_d{(uui��=b�Rb���݃�[zr���`��������Oo��n��S�O��ې��eǁ��C�	�>��Z���/qQ����I��,�Cut��C�Jut«���ut���MPG�#ut٩X��-��i��E��So-YLs��?��*�H�M�Vv���@޵oQo��*8�wV��ޛ@�y������3�?� 	�WppEJ����!�����b �@$eǫ\2���q�>�Ubg���i�6=}��K���Q���Ik7>�yymz�^�w|�8�+��-w���@�R�E����w����o=�0_d���Ҽ�I�:=�X�dq�R��겜���LY�M�*s�b����Ʌi����_i���J1x��������R�x�FL��0��Cv�~��5pv,�^�.]��H�tt�tmn���sV��+O�*<<�j��|	ʱV	5��  �����y�2ż�3�т�P?IKO�����U���ѐP�Υ�Y����������ΎLN�Rm��Nu~A�hU�^u��q�U1gr����(�DE�D_��	�@&*<1�2ї�3)��5NB�"�&��"��v ;�KY�DZ6�灁+FR��?8vŊ�&�=D[RwGjL��+�RydTq�5Z�E-󅅻uL��/��B�\(͉�'�+��u�| ~�4S��%��fJ��!s�����]VE���0�<5	B���˶@�?�(7+��Ư�\�!z^�sr$��!ȫ��PK	����@��!c�"E@��c�VY���0[��dn�J �h+�C0�'"����?�ͧ~��R-������,�,< E��/6��DN�6P�?�On<J���>:�l}a�D��Ь��YlOUA�9:ǩI:�eF���T�
��f��`̍��Vۉ�)����}{�{��&��3�>�K��]�r��%V��O�G4�U`W���PE<����ۤ*��t%6�,
)�u�cs2a7-�<�K�09�ҋD������+���h7ę��x@��J)VѵT�U��s+��p�IG���C+ �҃"/���k�8��;���XHj@��֠�����|����iX���r�\WtHʢKy��M���$]��y=�{�v�T�/�ނ�r�1���y�	waK�.�Lu7���9^_"�jq�܇5CCe9���l�m8C��X^Đb�=��ㅝ��#f���A-��C�Xƻs�{ǚ���b�a��v�Y�����8_�$v[�>է���(ɳ~E�ێ9 �דw(l�!�|��įI�U~�bX�R�Z�ݞ�:6�Ԓ��	����|�	�R${���ާ��:�4���4�B�� PZp$/�HY����T�p��l�4'~�"���隯s������7��%�? �-����\�k٣=�
+.9��J�pC��^��%�r��rR	7.������X��뺂q�ԭ�X���/j����
����px���r����q����:�n|d!�����G�e����*�S]����W�$�^MjK����-(u��M[�����=��;s��xI��J�j��a2����v#�vE�ĝV)7[��O)=������Y��=����IS��Z;�&�RD��|��yM8˃#f��YV��p�>�"� ~5��Ͽ�}:���$���M�଼v�-UЂA�<����Đk�A<&~��Ȱ�=!#y��"#�wAF�tA��K�5�6^��%1�v�	�9��搞2���9�nsHϘCzV�5Z���|T�vkX�n��8�	��W��K)*����@��)�����C����uc�n��Do����f{IK��ۿ�[Ug�h<��9���vFU;E���>�K!��i���xm���&P���P�%])��IU��e�?�럪��	��#
����[{��e�����oUO�4�-t;)h�c�n�\�J�c�ƚ9p#��U��p�?\���i7�_1�f�RF(��8�����1�~E�HX������e��F$,�\��օc]��W톯��hxg͆Mq��$<o��� <_������)�5J;�����XD�������}(jxR�?0�Î���c�Gj����a��X@���� >q��X����­�N�?	\��a-=�q]�Dl�(�r�����U7B��l�kt6��Ά�Sٌ��������-����b�+\歎��IxA�]��f}3}����l7S�� �/� ��I$��5�o�6�ᵿ���YyB��3��r���_�:^ �D�`�b�s�K���M��O������ ��7y����N':O��M�����E9 c��LY��5?J����~�|;I���"�78��B.�c��MU�s,"�m���R:?g?P��Ps� ���O���<����`\���Ȟ��*�9ɂ��O���ڮB����MC��_�Z0��=7p�q�'tˎ���8�ET�ȗP�[E�`����� 
I���?��~Y}=�B_Q_���~A��T�U�k*�u:�B��B8?���ʡ��Oq��8���3��wp��šg�_�����qh�����?ϡ��9���e���K����9=��C��8�"V��|p���rIf�ͲRfy,6�S2�pl��e�|lE���#�,��,O�fyV���ۤB�Z���|\s�-�xV@�����bW"�o`�n7�h���/�?��������/��;����1���5/R?�;��Ҹ�ϰ�Iz�!i?���/���O��;���.ˢ�]T���ר�ש�9*�KX{~Z�|&�L�e��l�q��ȟ�l�q�y�?�l��_�W���)��N65�{-N�DI�TW@��m��%q�5�DPP�Y�B�ި�����0��P�JN��$�\�RcZ�7��%�E2�HҿZ��k����1��@8P�"p~�zJ��`'3�9`4�`H1Hs�v��)�P��3�D6���%ӡ$S��N�� �&�v���Þ (^�����G��"׊7І�9z��7G谈�Q�r1&�_��y % ��҂Q�{n��Z2D�<�!+����S4� ���r�X����i0S+M>�f'0�PG�Ђ a!6iZ��p� ����m����6���Z�_��,�ݯd�����"DAI��x~p�`P��HA~��l�X�)n�	|��=,�����8Ҧ��s_��;���d�����S=�sKu�TX"k���D���j�[\he���)�\�m%A9E�kfVr��X����Z
oHsl��[�⻂"t{^e�08��A�?$*��5&^�b'&̓.zZyo�M�$�p^�
���.UV��sƝ'����wj'KQU��1�ͬ!�~���4��� �E���vvP<T��ym�P��ג%!.`���(�6K��0K	���1l��`:AYe5�˘�7��7��)Y�/�Sl,�M��Vf��"�+�M�`���ܕF�HR6�(z|�Q�Xd���f���b`cnT��bӢ��{ykX�b[�@�]���*[�Z{ �a�s�;�S�J^ߦ4N�'H+J���\���NX�����L��~Z��}N�5g]��V�}�շ�������	�`B6������_eڑۣ��)�4�}i�R�ݟϩ�-4�`����x�x:R�� +�c��ċH��nmji��D}.aj�_���?��6�^N	�?���p����̙���e�G���PN�3�J�Top�9̡9ȃ��<"�x�e�Bg�����@&�Ud�d���&s�,�ˡ���97�{�yr��S�ep�P�#����4�fw[�2�u�0#�]bJ���f&r�hJv� 4�L�����;��ბ��=vuׄ��u}���*�����ʭ`V�ɍ�-9[�{~O��6�:��9�J2�N%�Q���Pg��X�Yy2th�҇�I��"��,�60��{�(��CU�av�����4���J�Rg�ԏC:(~{�|q��>3���#1�M�0�2�Q���F�dP]@����c(�{L�x\�!ћἩ/�����6��$f�x��[V�MքH�/�,��g��{BNM��L�]�V�x�ݨ�t �H���`���X����^��dCL�^wRS�@�2[ሾ���A�\OJ��B�YĂ���h�3�tQ$�G�_e� s)ϥ��ç,�֤���*<��
�Fq�s*�������59Ӌ�8��?*5�����94�B�*4�B%�T�+*4�B�� �^V��*4�B�ThV��*4�]zş'
k���2s��!;.)��w=V��~�u�n`�M��Z�;v�d��gV�PF]GZkE�SdR�	�|
?���%��n���>J��v#Rj77'DȦԢs�~�9�b�/$����;�ڰ7�(G:A���=G�?��O �S��|�؄���RI����v��ޝn2��H�����;�,�ǿ�"Y�pY�qَ�ILlYK�6�VN�4d�Ӳo�l���,�"fi�Û�:t���:�ܗ�[U�6�\�oWK|.�mb�o
.q4����E������/zP�v_bC�*�\v�ЋF:841�Ƃ�FL�z&�-ϖL�$D��D	;)	�9Y��d,(G+�x<y�6�M�V�ԥ�̈́�$�r��"m��ƈ�����-@>۽�kOwΗF�=D�b��P;��8���~��e6wt�ͱ�J�n��b��*�������&ؤȆ���f��w���!���PK��Qs��͵Rsm������ک���9��`Q"v�;���Ψ���~���`Y������ܪ��VQs������ͭ�����I��u��,9�=Q�ރ�\{?��.,�,����׫������j�-�c��_����S����V}�K<5�ˎW"<u)W��W������KfdH��y���y�%�?M#��q�+���꼀(Mw�&�dΗ��ĥ�=�X��&�gf(p�]�K�E�^=2�b���We:��D�+�`d$:��Տ�W4I`4�vaÚ[�<Q�)�6=^���~�,��(��/3�}���t&~¹2_*͊����o�Ztn�ff�ם��Yg�8S�,�l���h�z�:"zg`�&Ș#b�E����O��`�>*�p
�4�� ���!��K�3��,ui�1�{���I��Q��ė�^����]���@C���t�!��w�ڜ��$���$0HV��:�DOHWu�YwF�י&��|dgZ��X�D�QfP �oM�7����_��u��
�[)~]��JO�ܝ���*�ڝF�C��A��[+~��o��m���I�z�o��mI�*[dr~������K�v�_�hm��<�����y��������t����_�?�-·���xH$�9E�a�ŏ:��������x�?^t�U�?�?�F�X8�ci�?.~'D������;-�ΤU�#P�,g�l'@!�Ήߠ��g`��1�F*]������7�վ[\�c_�!�C���HA����i��v��}�s�h]�KM/�ƽD��ҽt�h`�
��2�2�)͕�\����N.�M�SE,<�p3�f�)�,�G�<��p,h�秵e��3�S����Y؅�P	����Hj<��������ɥ7v͢=���?�H�ZҚ�!��i�O(��4���\Dt>gYe�h|i6B/�n�d���C����D�l���h�.�������@M�m� ؂A�8��؋����(�u�b���ݘXqP)'X�8 ��(K��s[*i!O0>�)d;9���f�=�PZ��Q2�Uf�A%�;U���)����9��W�U�:���<;:�����A��Э��k��zAC�礧x��s�ƌI�e���H%RR�	Š����II��!i��V��K!I\�H\���N�ڢ��Z�)W��ߏG���7*��nC�����\ֆ��0Kcl�F��)6K�����Y]h�Ӄ�Bv8�+������	�?��I�&�ʩ�(5�M��tR������`�k�u傁�8�D�R~�)˓���'Ph4i�0v�Q[m�q&�qH���Xu�/J�&ebX��<��Ѝ�$	b�#�n |WJ��	ْ�́��$���O;Dhu���?�w���Ϋ=ŊǢ�Ƚ,����aɟ�>�r��ې�]%�1Qo]�����Ԡ��@�=p	�lo�nq�T���*u�l�ke��V�F_+O�/��� o�O��X����qU<^�y�
^-ݔ�xE�˳��5��%�ߞ�s�_�%p��J)�>C�rq�?�g!"�yjv��q�Z�\*W��d�Ly�XU-��a���H�����%���U��2������X����)T��'� ��
���@�l-�Yt@�A�,tf�ׇ���񖮅+\U�0����a�~��y�D��KM�c;��O���i&�d�A������H�`_CĞ��U�̩kPvB*�7�0«�Mƥ�r��p�VU��.�����ǘ��۳v����,��Tg!d�\�:���Y���e�U�%�KG�Ge�Uv�dX�A�m)�&�f�;����Nl�e���GfY�e�̲.6�:�pb���W���u�>|�o�7JG��$��b!X��������G����߫Nku3,K0yk�n��oC�Ssio��>�-����1�i�6�,�׎���j�˗�N&z���/EgwyA�!k�0�N-��R��U�ˬ&��!�e$f��Y������KĊ�7�HZs�Ę���(�f98;�o��eNK#abU�D,�#Zg��yr`.X����A��C3��X�^�����־~1��o&����w �vΐFq��&U4�����9m?{�wh����� �;^@��`�E���4x���]~G�*/�ȹ�q�
Gަp�m�H�$=M-#ؕ���Z�q2��4��T�%�Z �n�W5쏟e�s�LR���P���h�AC���B�&���8ܯ�c���c��������l@�\�el05$s��<��x��F�#׮D�kģV�y��c��c���O�6�R$)�.�X[�H�A�h�	��,�"�|�Ǽ��b���U������Ů��ܮt��/5���<(m�X��P���x��;PW�(jI'���J$]kx����<���ζm�z���n87�G�9����MGUE���fEc�j�|���������_c`c�ǩR�!�>ˍwkā)�i�l�P3zy��סeH��r����y�S��v�bE��h�PԦFGK!���G��$���֙�pt�}
�A˗�	�h��yX~�G�j���Ձ��tgAv{ayJ4�5D/lH������|i�4/&T[���������`��è����%i	�u$Gq�X/Nh� K�H ԥ�U�N�8������6x��B5R�8���� s7;�En}uС�5��Fc��6c2< ᓄ�X���ip��v��􋚕����C?4�?4�-IZ�����?�������)��a�����ЅV������׮1�3<z��2��v�(o6|#ߵ�Ё�����޵����/s����1y��蓧i�3(�.y���g�`�o¿��P#����p�-�]�&:<+{TH4���.��ിCDv��N�)#�Dd�����2�/"�2"^D��+"{ed��쓑�"6�Eg�.eD�%AdJvJ���a��C"gP�� 	n>D�&��ʇ�a��S3��"�0��2�!U����s�?��}�[8���/��N�[{
�Ux�#;�(u+�+��S�[��Vեƕ �I�9�	�+���)��mۙ�"9�Ӭ�"���`�Ӌ���YxU�<!b2���O䏏��<�3�t�쑜-༝3���Ke�}@��f��y~2�ʫ�iXv�dx6�ȣ�H�畹�8�VN�*��7���J�t>]�u�	��~�Z"�� ��@�l��jú�&�AƬd��8�>� �9إ�rl#��5�AY�BŞ��	@�h
G��ןv���ϸ�m������]�~�����4��G�^\\�/�h6+�ZU���Sl��a�N�O�S|�����%�]}DR��"G)�0A��I�����}����O�Ut�>C����,��s��P�sv�x��G>�0�EN J�X�t�7!�!s]�)�uͳH
��x�s���c��"2/�CN\��|9p9qr1p�-�,MZ�����OI��E�|@���G��+����;�z,��8��E�����҆p���_+OA@|��>��
����e�忄V���Z�<���tjg�̏VDZp�"]�s�t�BE��;cq�沂��~2����؆��˸zII7��me�ܣ��ث����ӳ�!2��*�E�QC����]0#�GDg�bڥ�R�J⯧g�����S��-7\*N�����s>.�-̗��X�F�@Cg����*��KR�@�(pp#�rc�S�t��Xy�|��/\+̓����\i�P� ���#�����ԉ��H��:	u:��BS�ψ�,_�S�\�(g7�BP`�X-�ϧfJ��
	jh����xF^5���sj\toB���C�}�t�S)�LO��A@�K�9�H,���xqf�8�~�TYL��ѻى��p�fyAҚ�)���)�d�, 
R���l+���E�%�*�/Οbu~��%t�Y��M�3�A<��i�f!"&�3���e�MO�1]�3�0�Qi�1 -C�3���%<\�A Xk�ǿD�a��	iޑ(�R@��
\$�G(�����6��9�la���T'�&6����T�h1J��V��H�׫��{�=�*��;9y
�sd������~w�d�U��n�����̳ڌ�A�:���L�c�����{���<����F�e��l�a`�^��i�a�799)#[��6�;����lG�/���wph���C��~�a��I��������VpF�z(���r��%�"'�asn�xo����ޣ��Y��e�~�?f�>��1�w�Nxׯ�e��G�G2r�{�ߔ���i�޽�:#֫�z\"�����PsEF�9eF��i���|tV"�bǞ�W
	�J+t����A�ݔ�`|ZX���wn�K�-���W��U��e����J��U�e���U��e��ya��/Z�/-k^�{��+_���S�!�V�O[�<��=;b/:��>��O��s�J<�V��W�^���} �,Z��B\�K�����`w��7F�q_��./��^�<�S��*��	��èwl���-���ŷ0��5��2�ި;��t�k-�y�q��}�{�I�t2ם����w�q�/��M���vV\aD�iC��"p���+���`D���\ڙ@4��B12�-s&��!����؝g|�T��4؍�}����`둨�����T�r}�����D=��m;rP����3�������'o��PQM���3(jv\dij\s�f�m��L,o)�97�t�F���ۑ9���=q��O5)����EU�;0
�Y���[�����f]ϟG	41m�Ye}��7�(���J$�
8yR�k�l���b�rn�Mf~����7��d#X�lR�7?������arc�r��Hk"c:p~��t��v�&�G��F��K�o卒�\T���.	&,��ȱ�d�i��4ƍ���!M5n`�����-����B�7�}m��aS�2��Y�;�קf/�M���a�	ͭ�,#�T{�Z��}d��o*&�k����c�&��A��!��Cwz���,��Z�E�Kȇ�Z�Y���$!���#I���x��ˣBэw �x{sB�l��5R����)�U��-�ϯ�R�?�<A9������TdC�=���b�ًL��(p�����Xc%��19=;�z٫�� �r驅�I���7���2c����W���s�d�E�u��
<���_-MX��BA��WO/̋Z����噪��]+�
����qK�H��A�./ �ݱ\e��3y,I ��mX�K�Ho�:���9>*�`�A4�]�6V��<�P�0��V.ބ�T\HCURJR[fN�us�����V|-GKD��	Pgt�\����z�0҃F����b$�K�9-y��鹠�>L��JΒ0f0�/C�9f	%�Dgc8�	%\B��"�9�܂b/#q$�V��r7E'1�<t���mi+\a#W,W}�*��Ġ�\ �~f���<"p9�C ~<�D��yg;���a�t�ڋs���B�����U�At��#�+�oH�Q�W��<��1'�B���pg*NOr�K�XW9[Q��*JC�pd���;;$�L7'i���/0�5��n�����^K	�_���d�Ѭ�6��6�1��A7�؟���<�7|K���%}xX����"���*�l����M�1�F?��.-7r��A�'	
s����D^������Kk�D �@�k���m*��+o��`�_ܮ��N��s��?�]�/p����/�<Fc]-�բ�F������I���9@�A�]�Wi�+�E�in� ZXNqO[��xT�୒�!��J�8+�����◽yꝴ�oׅێo�A9�h��a�P�`	Q!,����k�n)��ޒ��t�ȓyK~����H���ţ&�F@�p�	/�4i�e�o�m�	�:�3�o�D�Ϙ�m�%g S�d��Ȩ	������i8}[�]~��2lͿ��2Rd+C�V��\++i,��GG8�@��6�B�0We"ݘ�u �ړ�����24��7��g��Cn;z��&��,�d~;f9׆�29b�;}KziI)A%)���I*'�b�=CZ�4�,��� \�I�@��"��-B9��3ʩF5�9$��4	���@�88�8�aC=u '�#��BImsQfj.�-J�K�̸E��̆e����	�E�g�x]�#�/�FE�ū��&��8�pS{'��WO�ם����b4 [M�]�B�G�BB3/)�c.�nKG��;��{�=�H���/�V��p����7SS��X�9���Z�(ZZ�|B{RP"	{��E�JW�۵]qO��`��"�ޣ��݆���`��/A���&���=��_w�`��z�;?L��!��u �� �Z�%������v8aK��rî�D�(K�y4������KHĽD���������[7%�n�Y{Eu��2MF��f1�h���g�ƾ��=qY:`b�'(�7�d#Q|�#�k�t�,�s�yr	�%��K*X$�BG��>::�B�z���NG!������yy�y��SN�������̷���]�=���;+1pJ���=���F��N�������R��`h�z��b��Z�z4�,#��5J�e`f�3S�J��3���h<7	�F�2j�(<����3R�ם0��G�1�[j��n��吴��nG����_-�4W��Q�W}ӤY��ux��-G�xo��V/� 1��m�G����+9*�қԑn�td����ty�\G�zo9,���"���?D3�~>\`n���HK�`hQ������8��ś�j��h���nw%��ѲKiFP��Q��>g���[��P)Y��H�x�FȾZ]��n"̙E�8�4|&*<����&����޽L)�ƫE4wŭ��Y�3#��B	mؓ��E�U��iRʾ�8�N���\�� G�� �=_�)�C7ص�n[�c�\hzb��fF�	����-�� �s?�	�KZ`�Bmx��c��"�N߹�< /���j�i�lXcfݪ��9�Ǫ���F0Ki$��`�#���-"s{\�(�o�vJ'��jxW�U��P����%���C�1�t��|g�e��j����Ֆ{��ʛh�f����*a�v�����ս��$�Y7h��Y��zz[^�5)�߈�qeУ6��z�g��ۗ�z��Q��gSÛ�:��ǲ�����-�}[�Q�~�m���Q���V���ds$Q-l�ۥ}c��Y{�j����1���l�̸jĢ��k~�	���{@]����n&z_�B���Q6�2kڣ��^:*?%.daq��mZ��X3o}y�l�^���UJ��C=�9xrD�< ��p�XD���y�a�#�RB?��p$�_l�?������|-�*d�����fe���T�s��*q��C���T�����c|m<Q�q�8�n(i��L����D�TfĀ�������蠍u��
��A�P�s���ܝ�/�Q����������k0��\ua^:=��&����9�⪅y*�?
�C���pf��*6��K%j�B�V3L���R eT��#�*6~ǫ�Y���<�m��"��
�953s�� ;�OSuP`�R�_*C��t�gg'hB!2 �~����#�^�.mU�SP��
�����Bx�T��thd�Z��-Ϟ�/^1z1i���AVe�P�Rq~|
�g�}�L)���N��H�����TA;W9�rp%U`�S?cU�=�ꢄY1�b ��J p�];��i1�ձ8�A= I/X��d�j�|M�3̔g3�f.5�_(�ǋ�4=&@u]�\|�1J3�m��x���/���Jiv�L(�+�$���xp�1{aB�oֈ����J('�{���!�,A�Gb��zQM�ბo�jEL-��ؔ8Y�_.��턂N�h<�|���-yNK�0,�H��hEbp͢�e:�������;Z���fk�Bm�F0�p֩��=�>�)�%�/��$��i�� .�G��k76�E�Q2s��AY��^���B��!$r*S#�B����w)�f��
���7��b��0mQ�~VQ��!�v3&o�if�d��h-mm�N��6'�i���^�B�.[`�����\�f�� [�q)	㶀���ڪ�f6i�Y�#�(P[Af��-~:E]�Wxu)Ӷ9JXe$h��n��15��ͽ�0W�ű��܄���Z�S.dW~Z'~�o�i���
݄oM�ql��Y�kۤ���d�;�o���ji�=H1sm���"���6L�.�+�6�w`u;̷�� "0��Nyf��/&gK�)���M�`��݁��A��l�l����ڙ�u�5��#�о��|^�o����j8��O���g�}z��S`ݘ�p�I����j
�)@��k�����N��*Q==�G���1�� �+�y���!�O�-�����kW�%��+�T�;�(�Y��Nj샃]��T_�L{�Z`�f������֩����QW>`�����%p<l�l���D��vGI'��0��NѣzG��O�ӿ���3�6g
V�{u�h(+=bƏ+�f?�r�g;g�SǶ?���)M ,;�8U���[�;Is��BA����)Mn�vB����T��W����*��I0`~��4��i��UwF"X�!�g~C��=�Y��X#�U�݂�(6��5��!���y�Q��9Vx�p�?���($�Ȃ���� ���Y��;�&kS���9�iD)]���NL�;�3��Յ9�D���ӹ��y���Y������6��4������xo'ﲒK&K�#�J�yߐɏKaH�A9��DTb>*q$*�BT�Fb�L,�\�.�+��� ��ׂ._{��^����^bDv[��>eT�H����>�wu��V��s>m�P0�ַ�����ҥ2��O��g=�����x56��|�(�e������6�b��Ry��az�C�#>j��!����|�Z59]�z��'�`z��[kL/XcZ!�O�&Tq�dO^ N�F� �"�����2|��M�Q��]�Q����ٗȇ�?��Ǣ�����9���E��+2>���"�0Vp(j N�1�9&K��`��u�E�/�A����>YК�WDS�����f�� "��؁���HS���e�#A������h��Ҡ��$�.G��r�]����]h`&�.+|h,�$�oXE0[&c�0����0[&L"f�dL�d�Lƹh[l|I��G�d�L�k�d��D̄ɸ:�[��N"�Äԑ�P5ʂ�����`�DAI~"W��%"0�U%	&���j¼�E¿S�w�§���0Ë�X.�K��ZF�pղG*�H�"Sz�����yI	�'��z�!4��.�k�9z�}<�4�6~�2���'k��߳��Nf���h$%	؇�*~�8��u=��c���)�v,���g��N'��x2�-I���K��2r�Q����u�&ջi�N�#��sܲ�����������gs\)�[�˾[��
|)-��Ǿ|�6Q�Dyb��@�����?�z?A����T�q��I�{Рq�F�W;Pe::I c���b�`���G*������ԏ�b=�>�~��ɛN��a���᝖�;���V�$-��J�i5��wX+RiG���^�ri��)iÛ�؜z=t˳�%�F�b�� O��K�X�,�j�i\2�Ĵ�q?5|�U��ߊ"6���W�]��^Hq�(���2�����e�r���D��<���ľJ�^?��`��$�C� i�E�'E0��}� v;N�nNTQ�ǚyk˔���Y�.�ʍ������1}���%y���X3u����K��}@Z�~>4�gTʙ�9�Lbi��)�*z1tzIB.�����SҘ���OهF#m�J�-�YL�5&-ms��1�o��?�4xZV���3���2�^<3�����d�ȷ�l��_Ft�ͣ��=��&�"�	����5�h�,���J�Ե�X�����F�hU�\��l��Ɉ��&܃;�e{roWj9���v�M=/�S�X]3��9��&_X8J�4���_Ej�D�jR� c���cUKtW��Cmt��^��X��z����o������v�_���ʲ:����o�7I1{fkm0�7ɬ��k�qF�����wlW�Fu0I�|(��'LiГyu�Z�]���N���X��ld;�=��:�8tR\B�2+i�a�uG�Q̫�63��
K����}@�����*�g����%�)���<Gn��G����|B����~=j�\3�JN�'fA�;zS�k�y
u18)��O0s�e�[1ȯӂ��1�ϯGK��Ê�ד�ᓒ��QߣS�*�����HM݊��$�����w�a�(��þˡO�s���0���9��C�V�����p !�?�X��G��Jl����e�Y��+�ҡ������:�C\I��F��m�	�u%��Chq�y}3��=�Hm_"��ȕM�^(��6�E�Z������//�\"�(�!�ި�������X�̃c m��v  ����R؅)
�J'��OR���!qW-�%ePQxF��mC�0g�3�K�} �J^H���Ԣ�O2�	� �����������B���W�Ao.��K�w�ngؖ�J�䁖ayUikprWh
EI�8Q0��b��+9S ��|ڇx�M�zi���
����Bsř�ぽ	�|��I��õ�zi��F[�u"�3�x��i�p��)�SW�2ދ�0�6�-7B�;�W_��P����P���J�0�~3�����de�/�.���;�+Q[P�'�*���J��P����?F~{2��Ǟ	�D}�G���,�*�A�d����K^i^�ԤjR*�?P�9ëw ��e�0�z���Ȼ_x���UZ����Ah�
�q���T���6�}�I�w����F���F��u���F�ͱ�%��G��@���Gy��<	[c�$|�(4����2k��(y�%{Q����TL~�l�K��s~��w��E���<�ҁ�)��*�8��7�����Oጝ���T�:<�[I���S�)bL��'�7�6l%z@�L��iY����x��;ư1�-DolP]L�^��w��*�xT��rj���������Q�Mj�~�����x!HNlB����?3fH<�;�lag���Ie�	����%&v@�ϔp�H�R�)=��P�F �7~��C����f�����x�U���JVl����Ho�6����?	��c��eyT�,��e�[�,���A�i�87>�����|������j)�K�S��C�=P�3t�Ȗd	������JI���0�ml!�X�SUe�Ώ�j��A5E����ɰ��V�j����J7�R:o�����*D�Z_P-�G(�U�f�ǥfbx�L�#kr�����f]�C@m��!Zc �8y��
\�E�}�o���=ɜ �r�ZѼ��i���H��x�@n85���>����&M�;�Et�	�爲Mn>6B�v�dh�<3eoQ�|k����z;�,Y�2в7���%�ۏ�7�S��lM|��<�g���kз���)�d뻖8�d�`Y�7�{��W����,P�n��Z�kY"�-��qȒ��ړ��oƀ��D&Oi��?�`���%��q��[�(�ڂ�a����z;�iÒűon�ŉ�E�G�Y�E�J���l���Y��װ�|�Oi��6V^6F��^X\j�Qꑘ�3�#�[�U&��FܺS����C"L�$T�ȕ��b 2d� �	}�l�f{%���Ń�Agv8�s%jS}:>�f�.o��o�n�bn�9�t�1�[Xi`&�{/'��Y
���Zǂ��BΟŧ/=1C���<�&V$o�唚��+.qA
#�HȆ��r%����������N/�ͦy�s��Pܼn�4#"�{+���n��Z#/�Zk��K��*�K�\M�Vy����7�m��m�ϙE�v���<ƆVa��c>�/��I�-i�.&scD�Ƹ̭�ټ���f��3�x�Ix�d��yS\�u���e����ysD��q��Fd�
lz|�)F�@٥��)�S=���Sx�x
�	2Y�k{?x�̹��?o�"�/%�F�X�ϻYB?}�H��_�*�'�9�����y2�!�(7::Sz�4�W�����*34��[LW07�`0�e�� -e����C�l�d�<K�To��
'Cv���5��m�P��ruz��ƓA#��L�`���)1�I�,�p�LBݑ�R�8wj~z���Vt��+i��<4;U����+T�>f/M�]�d%kGX���2��?h��M�ӳ�{:!��kђu����
��SH~�GZ�VO��B���k,��b=}�4����&�r�a�ȬTI��|��|�p��������C8�L�A�P�o����,�������ߩ�p���'�zޟ��?`��nF;�wţ��;�I�*�f�������o)/�����Ȉ����o_�Mj��i�4 �9��.��G�l��H�����ؽ����J3�'�S0y��|�B*��x�u���t�Sߋ�m�����m����[!%���/<)$l%k�����
��9q�����4���vQ7uԶu�>`����ܑ�<�Ii�~����9��T�T�<5�/-_��8h�/��q���k�~5��ф9���j�\��PH���H������Nu$�kq� ���<JY��̏Yf+���	�^�R!O�����s���(������9��@<ow����q�HȖ!iy܆���>�h	��bQ�MK��Uzd`����Y�9����׼��\i���
~0B������-k�������.�K}��boթ&c�0������Z{Io����� D=Tb���MD�XBt���}	�)Ƭ�VH�W	�W	�Wx�� 雕݊�g�ƥi���h��y�D�>t����K߇��}��!�6��0�f�}�qs����=QP݇�(��COT�aF��[�m�G��.�]|)�#�����n�1t6��!����5�A�HC�X)�ݜ@���[�{�W�j,��Ǖ��#� dFRR~�.�
w;����v���V0���>/uɝ��8(3i�x"�T�����LH�1��	>FK[>�\�+ů����_ ����v��s��v8�����O+jY�S�{v�>����F:
J9I?�Y�)#��ky%I|(�ҝH!"�b9��hϹ�Ͼ���Or��]��f�G��"�`_sB�l�����`�!~kXJ\l���ⷿ��A?@�e2�UZ���1O���~�*��Ue��T�XĆYO-+]�}|z�M����5�q<�I��mu(�:f<0�hyg�2#9Գ�M~�D����?G��-�Ҟ���1�״~ʧ���3���Y�N���N��N�
X��,�x�]��g�*� _4M�!G�s�yO��ݧ%�. �g��P[DC[�j�՛Bu�H��y�
���ͱ�A�>l%��u���vٻ�]���`�R��]�5��ZZ�<p{��䵁�8y]`u�8�g֫Cz���!�/R{f�<?�&�7%!��u�b�f8oȒ:gB��1�v�i�j�
�3=A�1���	y@yЎ?���S�$���4B��Z�Y�t�J]9Ȁ:��8&4��t������oU�j?.�^���G.*�\R�Ki(p����؅e�׋�ؔ=kb�1Qڭ�\����JQ`�+y�T��w��@
D�1+y�4Yu��8�����ղ2�og�ʹc����KS���o�9��FܩL�=��q��=П�$g�R5�x�YA��ukK]�AۿR�����s�z!��~^;(~kP�rK�{����ϭ�2ek��m������U�s���6��hg��N7��ʧ��r�Q��I�2GE��@�#�4���&ְt�2z�ҐR�����J������8y�vG�����	ۣ�k���8�������&���9���ʡm��[Y�4���[uG@�6��w�}&y�]�s���nu�P�Xī�Z��?�R�7���ky��qM�
z`S6�cO�๩x��q�y��g8�Ăs�H�^�f�s+t2G�ơ��*΅�s3)p���)3�W��T%>7zȀQ��q����`��Z��ŉi1uU�F&��	q��K��YhF<9������ٳ0�ⲩ����<�Ϋ�B�`�������Z���.F�5/E�z��g�#8�5=E<h7��{D���}'7kR*g��״}�����[Vh~������n�*������9}���{Lw�'2SsH��̌oW�ud�fl�sw^�~+��m���S����W^��l�_X��W��f�����5��3W<�p���L2�1�i�_�Ws�&��N� ���ڧ=<��|,����3�7._��̇\Md�֔[��knּkn����5��]�'��I�k49��ڼ�i$�/(��b�`�uy��`���b�@�.�>�l��:M�u����N�"�����v�BYa�M���x�m9�I��6K��؏^@{DV���n�빍nN��#e�_���K6����2�J��%�%�=Y��j麻��X��^z���\�'�n
�Zף��c����t�XJ`�5+���A��3^V��k�
����o}�聪9E5'uͤ ��l�.Z����K#^�Z\\dMCW��]F�ϛ�?֥� �ٛ���	�`$pT��`T���IG���i���a�v��p3�><���k���z�7��S�z��֗5���%��d]-c^ץh^����sw���c�*5���{��7#`�{av��I�A�*�U��#4����Ն�:C�M8!�tk���4�}8�OG+u,�V�O<v(ra��Q�6�3+�����{�?sj�/�f�uÿ[/u6z�ژ<sX�JL9! ���8��ܯ���9d�g� z���]9O2�㗄�۾��Օ�H�i���	ެp)gs�kX%�Y7[�q�Ϸ�/�����d��9��~�?�d�:��C�;��s)Y�eOG�8&��#[} �g�� ©�ќw\����i�Rc��2��%ͮտNL�
�qs�iu���u<$�z̝tB�n�����soG����0�(ƿG��Q)~����ȧ��0�Y��E�$���:S?��O2�m�JQ�F�>NT8�f�<���t�j��xe�'�Y|}��u�Az��/7������?�	�>Մ,��A �}I��P$���*|LQ�*���x����w�b󧺡���$vצ��4�� 	���;��K�Eml�O3L� oI}
�+Q�&�3����;�-�zG�R�t�$C������PY1U��ޔ���wF��f�0�h�U�}���ʿ@V���1�� �ho0SC�`N�`x�l�EI4��IN9��	Xl��5�D���V��CI-M/�v����@���7�.��yͥ�
�l�(�"��R�"���"� 2�D�n��n��j����^g'R3`�~=yw#���}��&��� �zN�N�#X�x�;�����^�o���p>p�@�>q�ڕ��.W�ͪ/Y���%J��������h��}H��!ч��܆�0U"�OV���L*��T�f��O�D5��ӌ��f�B~.q������«K���w���߬c�Yk�f���ֿ�-�~,�Ѩ���`R�Io�{��7PX@���܏�!.?����������c���!���λ8����1�����W����t��7 �X��5����Z���ڠ�����F�ך��w���:o�����濭�ky����'��f���=��=s7+bv��f�g��W����/%��辏%!�yI��{��q���ջC�����Ę�^1��G1�6 1Ӵu�+�Q��9M[�)�W:������1gG��0f�������8���Ӝ�v��*Ǳ�6�eN��.G;�A8KvM��3�L)y[�:/�,�8n[�7į蹻щ�c���y��ӹۮ[Qje�g���"�*�dp�D� �t��Z/�,����X��n)���]�ت�u�<)��v�Y�,�<�sw��]W[�Fր�]�Z���g&��	���lu�<S�8}mn�D�?���RW�gE����6c&�g�C�p]U�?"�:���&eH�Lr-5w�t�%�� {)��2��E|��+�K�y+�l��i��و�5�Ȳ�	�k�c�^#^�f������[M�
Yc=���?���
__CPAN_COMMON__ Storage_version6.swf
CWS�  xڬXKo��>$��+�q�	c��ē8�d�dZ�@:���k�&� M��-]�L(R )'꦳����]���A7EW�tٟ��Ѕ{��� �uyϹ�}�w����}���;�~�e�OK��W�&>q�r���}����I�p���
g��o�	��Α�>�o½�	��o��w���K<��~�`8J���v\�?D�p����w�$^pC�gnķ��1Dl�0�C��z�Ċ��x�(
G�Ea�@7bn���d�*<�؎���ƴ��bi��C#£F��/$
NFa&�!�8�α��}��un�˰�^���Ct7��a�M16��Q|��w=�칉o��r���/�v�q�X�CW��g�6��y,�Q���:�wv�:�OC��pr{0���'�Q��f��Ob*�q��lG�;S���M�0p��������p�ﻘ�X��K�&:P����Q��K�E���S�kF��Gڤ�,��d��	�QbM�w�ȩ��ZV��\jEQ+s�TQ�\jUQ�s���0K��bw����]���� ,#AO�.[�y��r�%�}�m~��6�t��-��} Ju��E�ů\���=���6����C�_򯷹Pz�h_JyׄB�t��]R����� ���M����\y�!�ɳ���Q��y������q7��:�Sr7�q��8��8oΫ�;�S0Yb�t�B�d|�6������$�=���e�m�G��{��)iB�*7����n�qO�q�n��%8.O�լ�L9�W�,��ƖOkxEx��4˅��~ �Ӯ�J="乢W�+�k��	R�}!���`���^�e�+�/2�YfSBQ��4�ҫR:������ӫ��Y8S�z�/�D�����{@�KN|P�FpaĠ�6���a;�������R$F��F2?���K�^�O����u��*�ϥ��¶'��:�dk<3'e~�}d�U�>V�[t�����-��Z��C�ٲY��>�L���b��wOA�C��h�����%z��n8�A�����;;��)@a/tf��7ހErV���N�uq�p�11@t�f8^�xp,9{�������v�P�FG�O��%�(�����@�L#��E-��tr�_�yN!����=
��9F}��
C7�Q�-`�鏂n⅁(@n�����;��CB�m(���')��~�~A�������[��|RrF��n���w��>�l��{��3�a�D|�?;N�����>
 �� ������R��]��zÛQR7C-��"�h	�C�m�J�&gX�����&qE�Xд�4I�KV�"�������X� K��o�.���ܶ�oW2��e��N��"Q����4�n�0�bq��`ǡ�ح�"t�LsͬoX
'3_�Z�?r���<�VXK����<��m��9e����<�7�ZMi,��l�NW�0 ��un#;�57�1`������K��9c�@~òQޟ��p��̳�)\N�`�ښ/Q��َ�@����<���P�֮����K9�E�"qʳ¡�9�2u��*9D���J�Bڐ�T�_H��{�|��0O	�V#��a���b���
E}^�
���tC��&�V߮|��)M]��
&ݜ5��ԟ�uWA|I���Ȫ��d����|�0].��"����{���Vlq��y���D�W9�r1�:�S���	���+�B���j�O��P�M�}�[2br����ѻ��]ٜ��8,�GA=�-�/���,��Y�B锄���ԍ����p<)����X͟�@<䝲
頖���y��,���]� �T�C�#� �>ns������EP����|!��Y��,�4�\,K"!B&�d��$=;M�(��JtA�PK$�oZ�6|e����m�~��vg�y�ݴ 9����[D����/���2N� �  �� �'d�
__CPAN_COMMON__ Storage_version8.swf
CWS   xڬ�n������+��8V�8N�$v����1i���v2Bmɐ�h���P�JRv�Uv���B�hW��b��tS���
��{IQ�4I�z!��{����{P�?@� M��r������<������_����wz��s��[w�}`z�n��_ӫ&�Mn�s�����A*u�=�mhzn��M,�
,ݶ~g��(�zpu3��w�7=�����i����p�vޛU�ٺ��	�놱�4Q�͠�j�ަWo5L'�z�rޅ�m=Б�EaJf��]ө�@&v�c{�X�l��6�vu�4���%�����5|R0G;���h�*(�91#7=O?=����-�Ro6�Sh9�Y���,�;���s|/�e����>���]5-�֡x�S�X����mT�D>��)5m��x�
��˰�7��a%�����$Z�q��&���7m��[�r��n ��gá�%�������l��5�,��`�s�/m��2�?)��4_$h�͸�����m���L)�"�U¬�?�L'LK�M���d��I��y��
�*,U�'1��X)+��o�Х�N����`�~'��1����aL}�tc��0fb3����ad>�B�§1�r� fEN�b*�5�\)+?�^AKCr��aAo��Z<�8�4���ڕ+[ [kj�3�|)��m�dK&�Ifsm̖
��z������D�5�}K�v�b��d�[Ƹ4Zr�֜v�]&�W
_q�{�)hIR9O1p��' -Y����4�-�8���q*Z�(�0���j	%�vT�T%���ϕ��m�(��@g���ij��/�XS�`���6�L�l54�
�R�.��e�(1'�3�@a0+a��A�c�k��$��zBX �4՞���r��-4f�<O?p��_�Ûє�.����-�ܚ�EC.*���X=�G��*�BѦ۳\�>/���F����O�sdC�y�i����%.���zB�(/!���.�M�^�t��y��~^7K��3Q��mL`D�lL7>��~�����<���;�#`"�|��WJ"�s���J���f�Wb�c7ze�,��F�
��]�_�xNSr!�c$���X��&�� �� E�GB�/D�����0P^����l�]�w�-��]vo��}�|���}, ����P��O�����l����C��_=�%�zv�����Z�;�5^{FP}�i��3��z}d���X�}a�B�
�����\{I�d ��03r��B�)��  ǀ=)�(�{.�I���#��AX7^H���@dzLi�|������쇒M��R����ͧ���Vc_RE��V�"��F��ؑ�cG�ƎD|�(��8h|����x�f8Z<bcڡg��#��� �^lS�����S�݆{5�_B}��u��\v�U�ġd��N��c�ܲ�fw���p�9��F	26�.��t�4��o�j���uq��yŮ��=h��ش� �^�8�^�§j��S�/7�;ۃ��qt�]��Na;_x5�ܪVq��򛭭�rY�R�\�+�u�d��NI4<Д,ʧ~`6�Hc����:��<�����uM����O���1�]IDYY�#�D0�4�E�_x�"�{y:"OG���ij�)��l�iZ���������^-�pgRV�q��'�� �b%6L��
����L)�2�A�$j�#Q��ע�qp�7y�|�����d�`�D�b�esZ≠'��hV4J{5W���@P�f>�mZ�b��eQ�6���b]�B!ly�=t���\� o�@^���5��. � ��U��Һ�X��j�OXJ��h"�oDi��ܤ�;� ��\v3b{�[��A�5 b� �z�
W#���Bg�
;�^����1�>��m���~���(��C ��V�P�����k_���H��J��&��y3��ӂ��C��p�a�������}��AG�*�s�lw[�'���B4��l�泿���{'ܼ[
]QSËf��q�1���[���=�q��=Q!k��v_v�|b�/��_g�E��ȯEv+��Tߕx}�{�;���q��?$����juxo۫S�{��i�;#�\�A�i�'��5���6L���].,V�YmyVp
��=�v�P�$��#�W�m����B����^�N�g}�����ە�7,=kJ�j-�X�C:���s��;
|͍����7[���:(�f]���
z8Ѭc;���W����X�]��a
S����].��&�Տu��Y�`#�)��B�ʷWau����j�CeP��ܝLa*�h|Ty|���` %����������Z�/��To>C��=X0Ni�8Z�r�Î�>t~��!Қ*�ũ�(��	�M�)��V���팠�MtB���0^Ų;�}b?#߼hؽH��Jw �
�Ux[���_I³,�]*���l�]~%��tҿ]�\$�o�Ppu���m-2M����^,�s��%�5Ӟ�2�_�,%�k\>^&�w�d����4����xM��z��U��� ��U8$P�Oq��JKN�7bE�/   �� ��s
__CPAN_COMMON__ README
The Dojo Toolkit
----------------

Dojo is a portable JavaScript toolkit for web application developers and
JavaScript professionals. Dojo solves real-world problems by providing powerful
abstractions and solid, tested implementations.

Getting Started
---------------

To use Dojo in your application, download one of the pre-built editions from the
Dojo website, http://dojotoolkit.org. Once you have downloaded the file you will
need to unzip the archive in your website root. At a minimum, you will need to
extract:

    src/ (folder)
    dojo.js
    iframe_history.html

To begin using dojo, include dojo in your pages by using:

    <script type="text/javascript" src="/path/to/dojo.js"></script>

Depending on the edition that you have downloaded, this base dojo.js file may or
may not include the modules you wish to use in your application. The files which
have been "baked in" to the dojo.js that is part of your distribution are listed
in the file build.txt that is part of the top-level directory that is created
when you unpack the archive. To ensure modules you wish to use are available,
use dojo.require() to request them. A very rich application might include:

    <script type="text/javascript" src="/path/to/dojo.js"></script>
    <script type="text/javascript">
        dojo.require("dojo.event.*");       // sophisticated AOP event handling
        dojo.require("dojo.io.*");          // for Ajax requests
        dojo.require("dojo.storage.*");     // a persistent local data cache
        dojo.require("dojo.json");          // serialization to JSON
        dojo.require("dojo.dnd.*");         // drag-and-drop
        dojo.require("dojo.lfx.*");         // animations and eye candy
        dojo.require("dojo.widget.Editor2");// stable, portable HTML WYSIWYG
    </script>

Note that only those modules which are *not* already "baked in" to dojo.js by
the edition's build process are requested by dojo.require(). This helps make
your application faster without forcing you to use a build tool while in
development. See "Building Dojo" and "Working From Source" for more details.


Compatibility
-------------

In addition to it's suite of unit-tests for core system components, Dojo has
been tested on almost every modern browser, including:

    - IE 5.5+
    - Mozilla 1.5+, Firefox 1.0+
    - Safari 1.3.9+
    - Konqueror 3.4+
    - Opera 8.5+

Note that some widgets and features may not perform exactly the same on every
browser due to browser implementation differences.

For those looking to use Dojo in non-browser environments, please see "Working
From Source".


Documentation and Getting Help
------------------------------

Articles outlining major Dojo systems are linked from:

    http://dojotoolkit.org/docs/

Toolkit APIs are listed in outline form at:

    http://dojotoolkit.org/docs/apis/

And documented in full at:

    http://manual.dojotoolkit.org/

The project also maintains a JotSpot Wiki at:

    http://dojo.jot.com/

A FAQ has been extracted from mailing list traffic:

    http://dojo.jot.com/FAQ

And the main Dojo user mailing list is archived and made searchable at:

    http://news.gmane.org/gmane.comp.web.dojo.user/

You can sign up for this list, which is a great place to ask questions, at:

    http://dojotoolkit.org/mailman/listinfo/dojo-interest

The Dojo developers also tend to hang out in IRC and help people with Dojo
problems. You're most likely to find them at:

    irc.freenode.net #dojo

Note that 3PM Wed PST in #dojo-meeting is reserved for a weekly meeting between
project developers, although anyone is welcome to participate.


Working From Source
-------------------

The core of Dojo is a powerful package system that allows developers to optimize
Dojo for deployment while using *exactly the same* application code in
development. Therefore, working from source is almost exactly like working from
a pre-built edition. Pre-built editions are significantly faster to load than
working from source, but are not as flexible when in development.

There are multiple ways to get the source. Nightly snapshots of the Dojo source
repository are available at:

    http://archive.dojotoolkit.org/nightly.tgz

Anonymous Subversion access is also available:

    %> svn co http://svn.dojotoolkit.org/dojo/trunk/ dojo

Each of these sources will include some extra directories not included in the
pre-packaged editions, including command-line tests and build tools for
constructing your own packages.

Running the command-line unit test suite requires Ant 1.6. If it is installed
and in your path, you can run the tests using:

    %> cd buildscripts
    %> ant test

The command-line test harness makes use of Rhino, a JavaScript interpreter
written in Java. Once you have a copy of Dojo's source tree, you have a copy of
Rhino. From the root directory, you can use Rhino interactively to load Dojo:

    %> java -jar buildscripts/lib/js.jar
    Rhino 1.5 release 3 2002 01 27
    js> load("dojo.js");
    js> print(dojo);
    [object Object]
    js> quit();

This environment is wonderful for testing raw JavaScript functionality in, or
even for scripting your system. Since Rhino has full access to anything in
Java's classpath, the sky is the limit!

Building Dojo
-------------

Dojo requires Ant 1.6.x in order to build correctly. While using Dojo from
source does *NOT* require that you make a build, speeding up your application by
constructing a custom profile build does.

Once you have Ant and a source snapshot of Dojo, you can make your own profile
build ("edition") which includes only those modules your application uses by
customizing one of the files in:

    [dojo]/buildscripts/profiles/

These files are named *.profile.js and each one contains a list of modules to
include in a build. If we created a new profile called "test.profile.js", we
could then make a profile build using it by doing:

    %> cd buildscripts
    %> ant -Dprofile=test -Ddocless=true release intern-strings

If the build is successful, your newly minted and compressed  profile build will
be placed in [dojo]/release/dojo/

-------------------------------------------------------------------------------
Copyright (c) 2004-2006, The Dojo Foundation, All Rights Reserved

vim:ts=4:et:tw=80:shiftwidth=4:

__CPAN_COMMON__ LICENSE
Dojo is availble under *either* the terms of the modified BSD license *or* the
Academic Free License version 2.1. As a recipient of Dojo, you may choose which
license to receive this code under (except as noted in per-module LICENSE
files). Some modules may not be the copyright of the Dojo Foundation. These
modules contain explicit declarations of copyright in both the LICENSE files in
the directories in which they reside and in the code itself. No external
contributions are allowed under licenses which are fundamentally incompatible
with the AFL or BSD licenses that Dojo is distributed under.

The text of the AFL and BSD licenses is reproduced below. 

-------------------------------------------------------------------------------
The "New" BSD License:
**********************

Copyright (c) 2005-2006, The Dojo Foundation
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
  * Neither the name of the Dojo Foundation nor the names of its contributors
    may be used to endorse or promote products derived from this software
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

-------------------------------------------------------------------------------
The Academic Free License, v. 2.1:
**********************************

This Academic Free License (the "License") applies to any original work of
authorship (the "Original Work") whose owner (the "Licensor") has placed the
following notice immediately following the copyright notice for the Original
Work:

Licensed under the Academic Free License version 2.1

1) Grant of Copyright License. Licensor hereby grants You a world-wide,
royalty-free, non-exclusive, perpetual, sublicenseable license to do the
following:

a) to reproduce the Original Work in copies;

b) to prepare derivative works ("Derivative Works") based upon the Original
Work;

c) to distribute copies of the Original Work and Derivative Works to the
public;

d) to perform the Original Work publicly; and

e) to display the Original Work publicly.

2) Grant of Patent License. Licensor hereby grants You a world-wide,
royalty-free, non-exclusive, perpetual, sublicenseable license, under patent
claims owned or controlled by the Licensor that are embodied in the Original
Work as furnished by the Licensor, to make, use, sell and offer for sale the
Original Work and Derivative Works.

3) Grant of Source Code License. The term "Source Code" means the preferred
form of the Original Work for making modifications to it and all available
documentation describing how to modify the Original Work. Licensor hereby
agrees to provide a machine-readable copy of the Source Code of the Original
Work along with each copy of the Original Work that Licensor distributes.
Licensor reserves the right to satisfy this obligation by placing a
machine-readable copy of the Source Code in an information repository
reasonably calculated to permit inexpensive and convenient access by You for as
long as Licensor continues to distribute the Original Work, and by publishing
the address of that information repository in a notice immediately following
the copyright notice that applies to the Original Work.

4) Exclusions From License Grant. Neither the names of Licensor, nor the names
of any contributors to the Original Work, nor any of their trademarks or
service marks, may be used to endorse or promote products derived from this
Original Work without express prior written permission of the Licensor. Nothing
in this License shall be deemed to grant any rights to trademarks, copyrights,
patents, trade secrets or any other intellectual property of Licensor except as
expressly stated herein. No patent license is granted to make, use, sell or
offer to sell embodiments of any patent claims other than the licensed claims
defined in Section 2. No right is granted to the trademarks of Licensor even if
such marks are included in the Original Work. Nothing in this License shall be
interpreted to prohibit Licensor from licensing under different terms from this
License any Original Work that Licensor otherwise would have a right to
license.

5) This section intentionally omitted.

6) Attribution Rights. You must retain, in the Source Code of any Derivative
Works that You create, all copyright, patent or trademark notices from the
Source Code of the Original Work, as well as any notices of licensing and any
descriptive text identified therein as an "Attribution Notice." You must cause
the Source Code for any Derivative Works that You create to carry a prominent
Attribution Notice reasonably calculated to inform recipients that You have
modified the Original Work.

7) Warranty of Provenance and Disclaimer of Warranty. Licensor warrants that
the copyright in and to the Original Work and the patent rights granted herein
by Licensor are owned by the Licensor or are sublicensed to You under the terms
of this License with the permission of the contributor(s) of those copyrights
and patent rights. Except as expressly stated in the immediately proceeding
sentence, the Original Work is provided under this License on an "AS IS" BASIS
and WITHOUT WARRANTY, either express or implied, including, without limitation,
the warranties of NON-INFRINGEMENT, MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY OF THE ORIGINAL WORK IS WITH YOU.
This DISCLAIMER OF WARRANTY constitutes an essential part of this License. No
license to Original Work is granted hereunder except under this disclaimer.

8) Limitation of Liability. Under no circumstances and under no legal theory,
whether in tort (including negligence), contract, or otherwise, shall the
Licensor be liable to any person for any direct, indirect, special, incidental,
or consequential damages of any character arising as a result of this License
or the use of the Original Work including, without limitation, damages for loss
of goodwill, work stoppage, computer failure or malfunction, or any and all
other commercial damages or losses. This limitation of liability shall not
apply to liability for death or personal injury resulting from Licensor's
negligence to the extent applicable law prohibits such limitation. Some
jurisdictions do not allow the exclusion or limitation of incidental or
consequential damages, so this exclusion and limitation may not apply to You.

9) Acceptance and Termination. If You distribute copies of the Original Work or
a Derivative Work, You must make a reasonable effort under the circumstances to
obtain the express assent of recipients to the terms of this License. Nothing
else but this License (or another written agreement between Licensor and You)
grants You permission to create Derivative Works based upon the Original Work
or to exercise any of the rights granted in Section 1 herein, and any attempt
to do so except under the terms of this License (or another written agreement
between Licensor and You) is expressly prohibited by U.S. copyright law, the
equivalent laws of other countries, and by international treaty. Therefore, by
exercising any of the rights granted to You in Section 1 herein, You indicate
Your acceptance of this License and all of its terms and conditions.

10) Termination for Patent Action. This License shall terminate automatically
and You may no longer exercise any of the rights granted to You by this License
as of the date You commence an action, including a cross-claim or counterclaim,
against Licensor or any licensee alleging that the Original Work infringes a
patent. This termination provision shall not apply for an action alleging
patent infringement by combinations of the Original Work with other software or
hardware.

11) Jurisdiction, Venue and Governing Law. Any action or suit relating to this
License may be brought only in the courts of a jurisdiction wherein the
Licensor resides or in which Licensor conducts its primary business, and under
the laws of that jurisdiction excluding its conflict-of-law provisions. The
application of the United Nations Convention on Contracts for the International
Sale of Goods is expressly excluded. Any use of the Original Work outside the
scope of this License or after its termination shall be subject to the
requirements and penalties of the U.S. Copyright Act, 17 U.S.C. Â§ 101 et
seq., the equivalent laws of other countries, and international treaty. This
section shall survive the termination of this License.

12) Attorneys Fees. In any action to enforce the terms of this License or
seeking damages relating thereto, the prevailing party shall be entitled to
recover its costs and expenses, including, without limitation, reasonable
attorneys' fees and costs incurred in connection with such action, including
any appeal of such action. This section shall survive the termination of this
License.

13) Miscellaneous. This License represents the complete agreement concerning
the subject matter hereof. If any provision of this License is held to be
unenforceable, such provision shall be reformed only to the extent necessary to
make it enforceable.

14) Definition of "You" in This License. "You" throughout this License, whether
in upper or lower case, means an individual or a legal entity exercising rights
under, and complying with all of the terms of, this License. For legal
entities, "You" includes any entity that controls, is controlled by, or is
under common control with you. For purposes of this definition, "control" means
(i) the power, direct or indirect, to cause the direction or management of such
entity, whether by contract or otherwise, or (ii) ownership of fifty percent
(50%) or more of the outstanding shares, or (iii) beneficial ownership of such
entity.

15) Right to Use. You may use the Original Work in all ways not otherwise
restricted or conditioned by this License or by law, and Licensor promises not
to interfere with or be responsible for such uses by You.

This license is Copyright (C) 2003-2004 Lawrence E. Rosen. All rights reserved.
Permission is hereby granted to copy and distribute this license without
modification. This license may not be modified without the express written
permission of its copyright owner.

