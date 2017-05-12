all: protocol.html ../lib/KGS/Messages.pm ../lib/KGS/Constants.pm messages.C messages.hs

protocol.html: doc2html.xsl protocol.xml
	sabcmd $< protocol.xml >$@

messages.C: doc2c++.xsl protocol.xml
	sabcmd $< protocol.xml >$@

messages.hs: doc2haskell.xsl protocol.xml
	sabcmd $< protocol.xml >$@

../lib/KGS/Messages.pm: doc2messages_pm.xsl protocol.xml
	sabcmd $< protocol.xml >$@

../lib/KGS/Constants.pm: doc2constants_pm.xsl protocol.xml
	sabcmd $< protocol.xml >$@
