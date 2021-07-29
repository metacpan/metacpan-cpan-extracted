# define APP	"EekBoek"
# define PUBLISHER "Squirrel Consultancy"

; These are updated by the vfix program.
# define V_MAJ	0
# define V_MIN	85
# define V_AUX	0
# define BuildNum	27

[Setup]
AppID={{4f534cd5-1583-4eb5-8db2-b363db470831}
AppName={#APP}
AppVersion={#V_MAJ}.{#V_MIN}.{#V_AUX}.{#BuildNum}.0
AppVerName={#APP} {#V_MAJ}.{#V_MIN}
AppPublisher={#PUBLISHER}
AppPublisherURL=https://www.chordpro.org
DefaultDirName={commonpf}\{#PUBLISHER}\{#APP}
DefaultGroupName=\{#PUBLISHER}\{#APP}
OutputDir=.
OutputBaseFilename={#APP}-installer-{#V_MAJ}-{#V_MIN}-{#V_AUX}-{#BuildNum}-msw-x64
Compression=lzma/Max
SolidCompression=true
AppCopyright=Copyright (C) 2005,2020 {#PUBLISHER}
PrivilegesRequired=none
InternalCompressLevel=Max
ShowLanguageDialog=no
LanguageDetectionMethod=none
WizardImageFile=ebinst.bmp
InfoAfterFile=infoafter.txt

[Languages]
Name: "nl"; MessagesFile: "compiler:Languages\Dutch.isl"

[Components]
Name: GUI; Description: "EekBoek GUI programma"; Types: full compact
Name: CLI; Description: "EekBoek command line programma"; Types: full

[Tasks]
Name: desktopicon; Description: "Aanmaken bureaublad ikonen"; Components: GUI; GroupDescription: "Extra ikonen:"; Languages: nl
Name: desktopicon\common; Description: "Voor alle gebruikers"; Components: GUI; GroupDescription: "Extra ikonen:"; Flags: exclusive; Languages: nl
Name: desktopicon\user; Description: "Alleen voor de huidige gebruiker"; Components: GUI; GroupDescription: "Extra ikonen:"; Flags: exclusive unchecked; Languages: nl

[Files]
Source: "build\*"; DestDir: {app}; Flags: recursesubdirs createallsubdirs overwritereadonly ignoreversion;

[Icons]
Name: {group}\{#APP}; Filename: {app}\bin\ebwxshell.exe; Components: GUI; IconFilename: "{app}\eb.ico";
Name: "{group}\{cm:UninstallProgram,{#APP}}"; Filename: "{uninstallexe}"

Name: "{commondesktop}\{#APP}"; Filename: "{app}\ebwxshell.exe"; Tasks: desktopicon\common; IconFilename: "{app}\eb.ico";
Name: "{userdesktop}\{#APP}"; Filename: "{app}\ebwxshell.exe"; Tasks: desktopicon\user; IconFilename: "{app}\eb.ico";

[Messages]
BeveledLabel=Perl Powered Software by Squirrel Consultancy
