gdbus-codegen \
    --interface-prefix at.atikon \
    --generate-c-code webextensionif \
    at.atikon.WebExtensionIf.xml \
&& \
cc \
    `pkg-config --cflags webkit2gtk-4.0` \
    webextensionif.h webextensionif.c \
    gtk3-webkit2-extension.c \
    -fPIC \
    -shared \
    -o gtk3-webkit2-extension.so \
    `pkg-config --libs webkit2gtk-4.0`
