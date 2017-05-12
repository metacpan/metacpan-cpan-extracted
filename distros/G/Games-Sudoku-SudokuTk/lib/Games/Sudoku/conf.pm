#
#* Copyright (C) 2008 Christian Guine
# * This program is free software; you can redistribute it and/or modify it
# * under the terms of the GNU General Public License as published by the Free
# * Software Fondation; either version 2 of the License, or (at your option)
# * any later version.
# * This program is distributed in the hope that it will be useful, but WITHOUT
# * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# * more details.
# * You should have received a copy of the GNU General Public License along with
# * this program; if not, write to the Free Software Foundation, Inc., 59
# * Temple Place - Suite 330, Boston, MA 02111-1307, USA.
# */
# conf.pm
sub conf
{
# correspondance dessin chiffres
%dessinanimaux = ('1','1.gif','2','2.gif','3','3.gif','4','4.gif','5','5.gif',
        '6','6.gif','7','7.gif','8','8.gif','9','9.gif','A','10.gif',
        'B','11.gif','C','12.gif','D','13.gif','E','14.gif','F','15.gif','G','16.gif');
%dessincouleurs = ('1','#000000','2','#FF0000','3','#0000FF','4','#FFFF00','5','#FFFFFF',
        '6','#333333','7','#666666','8','#CCCCCC','9','#00FFFF','A','#999999',
        'B','#00FF00','C','#FF00FF','D','#FF6600','E','#996600','F','#006600','G','#99FFFF');
$nbsolution = 41;       # how solution have we save for maxisudoku
$couleurfond = "white"; # color of background
$fabrication = 0;    # = 1 if we want make many grid 16x16
$skin = 1;           # = 1 if we want a "beautiful" skin
}
1;
