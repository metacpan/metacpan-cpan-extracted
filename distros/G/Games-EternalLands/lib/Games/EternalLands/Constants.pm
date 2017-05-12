package Games::EternalLands::Constants;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
    %ActorCommandsByID %ClientCommandsByID %ActorTypesByID %ActiveCommands
    %WearableItemsByID %TextChannelsByID %SkinColorsByID %HelmetsByID %HeadsByID %CapesByID
    %ClientCommandsByID %NoArmorFlagsByID %ServerCommandsByID %ELStatsByID %FramesByID
    %ActorTypesByID %WeaponsByID %PantsColorsByID %WindowsByID %ActorCommandsByID %BootsColorsByID
    %SoundByID %ColorsByID %ShirtColorsByID %HairColorsByID %ShieldsByID
    $NO_BODY_ARMOR $NO_PANTS_ARMOR $NO_BOOTS_ARMOR $RULE_WIN $RULE_INTERFACE $NEW_CHAR_INTERFACE
    $KIND_OF_WEAPON $KIND_OF_SHIELD $KIND_OF_CAPE $KIND_OF_HELMET $KIND_OF_LEG_ARMOR $KIND_OF_BODY_ARMOR
    $KIND_OF_BOOT_ARMOR
    $DEBUG_TYPES $DEBUG_TEXT $DEBUG_PATH $DEBUG_BAGS $DEBUG_PACKETS
    $BOOTS_BLACK $BOOTS_BROWN $BOOTS_DARKBROWN $BOOTS_DULLBROWN $BOOTS_LIGHTBROWN $BOOTS_ORANGE
    $BOOTS_LEATHER $BOOTS_FUR $BOOTS_IRON_GREAVE $BOOTS_STEEL_GREAVE $BOOTS_TITANIUM_GREAVE
    $BOOTS_HYDROGENIUM_GREAVE
    $PANTS_BLACK $PANTS_BLUE $PANTS_BROWN $PANTS_DARKBROWN $PANTS_GREY $PANTS_GREEN $PANTS_LIGHTBROWN
    $PANTS_RED $PANTS_WHITE $PANTS_LEATHER $PANTS_IRON_CUISSES $PANTS_FUR $PANTS_STEEL_CUISSES
    $PANTS_TITANIUM_CUISSES $PANTS_HYDROGENIUM_CUISSES
    $HEAD_1 $HEAD_2 $HEAD_3 $HEAD_4 $HEAD_5
    $CHAT_LOCAL $CHAT_PERSONAL $CHAT_GM $CHAT_SERVER $CHAT_MOD $CHAT_CHANNEL1 $CHAT_CHANNEL2
    $CHAT_CHANNEL3 $CHAT_MODPM
    $HELMET_IRON $HELMET_FUR $HELMET_LEATHER $HELMET_RACOON $HELMET_SKUNK $HELMET_CROWN_OF_MANA
    $HELMET_CROWN_OF_LIFE $HELMET_STEEL $HELMET_TITANIUM $HELMET_HYDROGENIUM $HELMET_NONE
    $HAIR_BLACK $HAIR_BLOND $HAIR_BROWN $HAIR_GRAY $HAIR_RED $HAIR_WHITE $HAIR_BLUE
    $HAIR_GREEN $HAIR_PURPLE
    $SKIN_BROWN $SKIN_NORMAL $SKIN_PALE $SKIN_TAN $SKIN_DARK_BLUE
    $snd_rain $snd_tele_in $snd_tele_out $snd_teleprtr $snd_thndr_1 $snd_thndr_2 $snd_thndr_3
    $snd_thndr_4 $snd_thndr_5 $snd_fire 
    $c_lbound $c_red1 $c_orange1 $c_yellow1 $c_green1 $c_blue1 $c_purple1 $c_grey1 $c_red2
    $c_orange2 $c_yellow2 $c_green2 $c_blue2 $c_purple2 $c_grey2 $c_red3 $c_orange3 $c_yellow3
    $c_green3 $c_blue3 $c_purple3 $c_grey3 $c_red4 $c_orange4 $c_yellow4 $c_green4 $c_blue4
    $c_purple4 $c_ubound $c_grey4
    $SHIELD_WOOD $SHIELD_WOOD_ENHANCED $SHIELD_IRON $SHIELD_STEEL
    $SHIELD_TITANIUM $SHIELD_HYDROGENIUM $SHIELD_NONE
    $frame_walk $frame_run $frame_die1 $frame_die2 $frame_pain1 $frame_pick $frame_drop
    $frame_idle $frame_harvest $frame_cast $frame_ranged $frame_pain2 $frame_sit $frame_stand
    $frame_sit_idle $frame_combat_idle $frame_in_combat $frame_out_combat $frame_attack_up_1
    $frame_attack_up_2 $frame_attack_up_3 $frame_attack_up_4 $frame_attack_down_1 $frame_attack_down_2
    $human_female $human_male $elf_female $elf_male $dwarf_female $dwarf_male
    $wraith $cyclops $beaver $rat $goblin_male_2 $goblin_female_1 $town_folk4
    $town_folk5 $shop_girl3 $deer $bear $wolf $white_rabbit $brown_rabbit $boar
    $bear2 $snake1 $snake2 $snake3 $fox $puma $ogre_male_1 $goblin_male_1 $orc_male_1
    $orc_female_1 $skeleton $gargoyle1 $gargoyle2 $gargoyle3 $troll $chimeran_wolf_mountain
    $gnome_female $gnome_male $orchan_female $orchan_male $draegoni_female $draegoni_male
    $skunk_1 $racoon_1 $unicorn_1 $chimeran_wolf_desert $chimeran_wolf_forest $bear_3
    $bear_4 $panther $feran $leopard_1 $leopard_2 $chimeran_wolf_arctic $tiger_1
    $tiger_2 $armed_female_orc $armed_male_orc $armed_skeleton $phantom_warrior $imp
    $brownie $leprechaun $spider_s_1 $spider_s_2 $spider_s_3 $spider_l_1 $spider_l_2
    $spider_l_3 $wood_sprite $spider_l_4 $spider_s_4 $giant_1 $hobgoblin $yeti $snake4 
    $CAPE_BLACK $CAPE_BLUE $CAPE_BLUEGRAY $CAPE_BROWN $CAPE_BROWNGRAY $CAPE_GRAY
    $CAPE_GREEN $CAPE_GREENGRAY $CAPE_PURPLE $CAPE_WHITE $CAPE_FUR $CAPE_GOLD
    $CAPE_RED $CAPE_ORANGE $CAPE_MOD $CAPE_DERIN $CAPE_RAVENOD $CAPE_PLACID
    $CAPE_LORD_VERMOR $CAPE_AISLINN $CAPE_SOLDUS $CAPE_LOTHARION $CAPE_LEARNER
    $CAPE_NONE
    $SHIRT_BLACK $SHIRT_BLUE $SHIRT_BROWN $SHIRT_GREY $SHIRT_GREEN $SHIRT_LIGHTBROWN
    $SHIRT_ORANGE $SHIRT_PINK $SHIRT_PURPLE $SHIRT_RED $SHIRT_WHITE $SHIRT_YELLOW
    $SHIRT_LEATHER_ARMOR $SHIRT_CHAIN_ARMOR $SHIRT_STEEL_CHAIN_ARMOR $SHIRT_TITANIUM_CHAIN_ARMOR
    $SHIRT_IRON_PLATE_ARMOR $SHIRT_ARMOR_6 $SHIRT_FUR $SHIRT_STEEL_PLATE_ARMOR
    $SHIRT_TITANIUM_PLATE_ARMOR
    $nothing $kill_me $die1 $die2 $pain1 $pick $drop $idle $harvest $cast $ranged
    $meele $sit_down $stand_up $turn_left $turn_right $pain2 $enter_combat $leave_combat
    $move_n $move_ne $move_e $move_se $move_s $move_sw $move_w $move_nw $run_n $run_ne
    $run_e $run_se $run_s $run_sw $run_w $run_nw $turn_n $turn_ne $turn_e $turn_se $turn_s
    $turn_sw $turn_w $turn_nw $attack_up_1 $attack_up_2 $attack_up_3 $attack_up_4
    $attack_down_1 $attack_down_2
    $RAW_TEXT $ADD_NEW_ACTOR $ADD_ACTOR_COMMAND $YOU_ARE $SYNC_CLOCK $NEW_MINUTE
    $REMOVE_ACTOR $CHANGE_MAP $COMBAT_MODE $KILL_ALL_ACTORS $GET_TELEPORTERS_LIST
    $PONG $TELEPORT_IN $TELEPORT_OUT $PLAY_SOUND $START_RAIN $STOP_RAIN $THUNDER
    $HERE_YOUR_STATS $HERE_YOUR_INVENTORY $INVENTORY_ITEM_TEXT $GET_NEW_INVENTORY_ITEM
    $REMOVE_ITEM_FROM_INVENTORY $HERE_YOUR_GROUND_ITEMS $GET_NEW_GROUND_ITEM
    $REMOVE_ITEM_FROM_GROUND $CLOSE_BAG $GET_NEW_BAG $GET_BAGS_LIST $DESTROY_BAG $NPC_TEXT
    $NPC_OPTIONS_LIST $CLOSE_NPC_MENU $SEND_NPC_INFO $GET_TRADE_INFO $GET_TRADE_OBJECT
    $GET_TRADE_ACCEPT $GET_TRADE_REJECT $GET_TRADE_EXIT $REMOVE_TRADE_OBJECT $GET_YOUR_TRADEOBJECTS
    $GET_TRADE_PARTNER_NAME $GET_YOUR_SIGILS $SPELL_ITEM_TEXT $GET_ACTIVE_SPELL
    $GET_ACTIVE_SPELL_LIST $REMOVE_ACTIVE_SPELL $GET_ACTOR_DAMAGE $GET_ACTOR_HEAL $SEND_PARTIAL_STAT
    $SPAWN_BAG_PARTICLES $ADD_NEW_ENHANCED_ACTOR $ACTOR_WEAR_ITEM $ACTOR_UNWEAR_ITEM $PLAY_MUSIC
    $GET_KNOWLEDGE_LIST $GET_NEW_KNOWLEDGE $GET_KNOWLEDGE_TEXT $BUDDY_EVENT $PING_REQUEST
    $FIRE_PARTICLES $REMOVE_FIRE_AT $DISPLAY_CLIENT_WINDOW $OPEN_BOOK $READ_BOOK $CLOSE_BOOK
    $STORAGE_LIST $STORAGE_ITEMS $STORAGE_TEXT $SPELL_CAST $GET_ACTIVE_CHANNELS $MAP_FLAGS
    $GET_ACTOR_HEALTH $GET_3D_OBJ_LIST $GET_3D_OBJ $REMOVE_3D_OBJ $GET_ITEMS_COOLDOWN $SEND_BUFFS
    $MAP_SET_OBJECTS $MAP_STATE_OBJECTS $UPGRADE_NEW_VERSION $UPGRADE_TOO_OLD $REDEFINE_YOUR_COLORS
    $YOU_DONT_EXIST $LOG_IN_OK $LOG_IN_NOT_OK $CREATE_CHAR_OK $CREATE_CHAR_NOT_OK $BYE
    $MOVE_TO $SEND_PM $GET_PLAYER_INFO $RUN_TO $SIT_DOWN $SEND_ME_MY_ACTORS $SEND_OPENING_SCREEN
    $SEND_VERSION $TURN_LEFT $TURN_RIGHT $PING $HEART_BEAT $LOCATE_ME $USE_MAP_OBJECT $SEND_MY_STATS
    $SEND_MY_INVENTORY $LOOK_AT_INVENTORY_ITEM $MOVE_INVENTORY_ITEM $HARVEST $DROP_ITEM
    $PICK_UP_ITEM $LOOK_AT_GROUND_ITEM $INSPECT_BAG $S_CLOSE_BAG $LOOK_AT_MAP_OBJECT $TOUCH_PLAYER
    $RESPOND_TO_NPC $MANUFACTURE_THIS $USE_INVENTORY_ITEM $TRADE_WITH $ACCEPT_TRADE $REJECT_TRADE
    $EXIT_TRADE $PUT_OBJECT_ON_TRADE $REMOVE_OBJECT_FROM_TRADE $LOOK_AT_TRADE_ITEM $CAST_SPELL
    $ATTACK_SOMEONE $GET_KNOWLEDGE_INFO $ITEM_ON_ITEM $SEND_BOOK $GET_STORAGE_CATEGORY
    $DEPOSITE_ITEM $WITHDRAW_ITEM $LOOK_AT_STORAGE_ITEM $SPELL_NAME $PING_RESPONSE
    $SET_ACTIVE_CHANNEL $LOG_IN $CREATE_CHAR $GET_DATE $GET_TIME $SERVER_STATS $ORIGINAL_IP
    $WEAPON_NONE $SWORD_1 $SWORD_2 $SWORD_3 $SWORD_4 $SWORD_5 $SWORD_6 $SWORD_7 $STAFF_1 $STAFF_2
    $STAFF_3 $STAFF_4 $HAMMER_1 $HAMMER_2 $PICKAX $SWORD_1_FIRE $SWORD_2_FIRE $SWORD_2_COLD
    $SWORD_3_FIRE $SWORD_3_COLD $SWORD_3_MAGIC $SWORD_4_FIRE $SWORD_4_COLD $SWORD_4_MAGIC
    $SWORD_4_THERMAL $SWORD_5_FIRE $SWORD_5_COLD $SWORD_5_MAGIC $SWORD_5_THERMAL $SWORD_6_FIRE
    $SWORD_6_COLD $SWORD_6_MAGIC $SWORD_6_THERMAL $SWORD_7_FIRE $SWORD_7_COLD $SWORD_7_MAGIC
    $SWORD_7_THERMAL $PICKAX_MAGIC $BATTLEAXE_IRON $BATTLEAXE_STEEL $BATTLEAXE_TITANIUM
    $BATTLEAXE_IRON_FIRE $BATTLEAXE_STEEL_COLD $BATTLEAXE_STEEL_FIRE $BATTLEAXE_TITANIUM_COLD
    $BATTLEAXE_TITANIUM_FIRE $BATTLEAXE_TITANIUM_MAGIC $GLOVE_FUR $GLOVE_LEATHER $BONE_1
    $STICK_1 $SWORD_EMERALD_CLAYMORE $SWORD_CUTLASS $SWORD_SUNBREAKER $SWORD_ORC_SLAYER
    $SWORD_EAGLE_WING $SWORD_RAPIER $SWORD_JAGGED_SABER
    $PHY_CUR $PHY_BASE $COO_CUR $COO_BASE $REAS_CUR $REAS_BASE $WILL_CUR $WILL_BASE $INST_CUR
    $INST_BASE $VIT_CUR $VIT_BASE $HUMAN_CUR $HUMAN_BASE $ANIMAL_CUR $ANIMAL_BASE $VEGETAL_CUR
    $VEGETAL_BASE $INORG_CUR $INORG_BASE $ARTIF_CUR $ARTIF_BASE $MAGIC_CUR $MAGIC_BASE $MAN_S_CUR
    $MAN_S_BASE $HARV_S_CUR $HARV_S_BASE $ALCH_S_CUR $ALCH_S_BASE $OVRL_S_CUR $OVRL_S_BASE $DEF_S_CUR
    $DEF_S_BASE $ATT_S_CUR $ATT_S_BASE $MAG_S_CUR $MAG_S_BASE $POT_S_CUR $POT_S_BASE $CARRY_WGHT_CUR
    $CARRY_WGHT_BASE $MAT_POINT_CUR $MAT_POINT_BASE $ETH_POINT_CUR $ETH_POINT_BASE $FOOD_LEV $RESEARCHING
    $MAG_RES $MAN_EXP $MAN_EXP_NEXT $HARV_EXP $HARV_EXP_NEXT $ALCH_EXP $ALCH_EXP_NEXT $OVRL_EXP
    $OVRL_EXP_NEXT $DEF_EXP $DEF_EXP_NEXT $ATT_EXP $ATT_EXP_NEXT $MAG_EXP $MAG_EXP_NEXT $POT_EXP
    $POT_EXP_NEXT $RESEARCH_COMPLETED $RESEARCH_TOTAL $SUM_EXP $SUM_EXP_NEXT $SUM_S_CUR $SUM_S_BASE
    $CRA_EXP $CRA_EXP_NEXT $CRA_S_CUR $CRA_S_BASE
);

our %EXPORT_TAGS = (
    TypeContainers => [qw(
        %ActorCommandsByID %ClientCommandsByID %ActorTypesByID %ActiveCommands
        %WearableItemsByID %TextChannelsByID %SkinColorsByID %HelmetsByID %HeadsByID %CapesByID
        %ClientCommandsByID %NoArmorFlagsByID %ServerCommandsByID %ELStatsByID %FramesByID
        %ActorTypesByID %WeaponsByID %PantsColorsByID %WindowsByID %ActorCommandsByID %BootsColorsByID
        %SoundByID %ColorsByID %ShirtColorsByID %HairColorsByID %ShieldsByID
    )],
    Misc => [qw(
        $NO_BODY_ARMOR $NO_PANTS_ARMOR $NO_BOOTS_ARMOR $RULE_WIN $RULE_INTERFACE $NEW_CHAR_INTERFACE
    )],
    Kinds => [qw(
        $KIND_OF_WEAPON $KIND_OF_SHIELD $KIND_OF_CAPE $KIND_OF_HELMET $KIND_OF_LEG_ARMOR $KIND_OF_BODY_ARMOR
        $KIND_OF_BOOT_ARMOR
    )],
    Debug => [qw(
        $DEBUG_TYPES $DEBUG_TEXT $DEBUG_PATH $DEBUG_BAGS $DEBUG_PACKETS
    )],
    Boots => [qw(
        $BOOTS_BLACK $BOOTS_BROWN $BOOTS_DARKBROWN $BOOTS_DULLBROWN $BOOTS_LIGHTBROWN $BOOTS_ORANGE
        $BOOTS_LEATHER $BOOTS_FUR $BOOTS_IRON_GREAVE $BOOTS_STEEL_GREAVE $BOOTS_TITANIUM_GREAVE
        $BOOTS_HYDROGENIUM_GREAVE
    )],
    Pants => [qw(
        $PANTS_BLACK $PANTS_BLUE $PANTS_BROWN $PANTS_DARKBROWN $PANTS_GREY $PANTS_GREEN $PANTS_LIGHTBROWN
        $PANTS_RED $PANTS_WHITE $PANTS_LEATHER $PANTS_IRON_CUISSES $PANTS_FUR $PANTS_STEEL_CUISSES
        $PANTS_TITANIUM_CUISSES $PANTS_HYDROGENIUM_CUISSES
    )],
    Heads => [qw(
        $HEAD_1 $HEAD_2 $HEAD_3 $HEAD_4 $HEAD_5
    )],
    Chat => [qw(
        $CHAT_LOCAL $CHAT_PERSONAL $CHAT_GM $CHAT_SERVER $CHAT_MOD $CHAT_CHANNEL1 $CHAT_CHANNEL2
        $CHAT_CHANNEL3 $CHAT_MODPM
    )],
    Helmets => [qw(
        $HELMET_IRON $HELMET_FUR $HELMET_LEATHER $HELMET_RACOON $HELMET_SKUNK $HELMET_CROWN_OF_MANA
        $HELMET_CROWN_OF_LIFE $HELMET_STEEL $HELMET_TITANIUM $HELMET_HYDROGENIUM $HELMET_NONE
    )],
    Hair => [qw(
        $HAIR_BLACK $HAIR_BLOND $HAIR_BROWN $HAIR_GRAY $HAIR_RED $HAIR_WHITE $HAIR_BLUE
        $HAIR_GREEN $HAIR_PURPLE
    )],
    Skin => [qw(
        $SKIN_BROWN $SKIN_NORMAL $SKIN_PALE $SKIN_TAN $SKIN_DARK_BLUE
    )],
    Sounds => [qw(
        $snd_rain $snd_tele_in $snd_tele_out $snd_teleprtr $snd_thndr_1 $snd_thndr_2 $snd_thndr_3
        $snd_thndr_4 $snd_thndr_5 $snd_fire 
    )],
    Colors => [qw(
        $c_lbound $c_red1 $c_orange1 $c_yellow1 $c_green1 $c_blue1 $c_purple1 $c_grey1 $c_red2
        $c_orange2 $c_yellow2 $c_green2 $c_blue2 $c_purple2 $c_grey2 $c_red3 $c_orange3 $c_yellow3
        $c_green3 $c_blue3 $c_purple3 $c_grey3 $c_red4 $c_orange4 $c_yellow4 $c_green4 $c_blue4
        $c_purple4 $c_ubound $c_grey4
    )],
    Shields => [qw(
        $SHIELD_WOOD $SHIELD_WOOD_ENHANCED $SHIELD_IRON $SHIELD_STEEL
        $SHIELD_TITANIUM $SHIELD_HYDROGENIUM $SHIELD_NONE
    )],
    Frames => [qw(
        $frame_walk $frame_run $frame_die1 $frame_die2 $frame_pain1 $frame_pick $frame_drop
        $frame_idle $frame_harvest $frame_cast $frame_ranged $frame_pain2 $frame_sit $frame_stand
        $frame_sit_idle $frame_combat_idle $frame_in_combat $frame_out_combat $frame_attack_up_1
        $frame_attack_up_2 $frame_attack_up_3 $frame_attack_up_4 $frame_attack_down_1 $frame_attack_down_2
    )],
    ActorTypes => [qw(
        $human_female $human_male $elf_female $elf_male $dwarf_female $dwarf_male
        $wraith $cyclops $beaver $rat $goblin_male_2 $goblin_female_1 $town_folk4
        $town_folk5 $shop_girl3 $deer $bear $wolf $white_rabbit $brown_rabbit $boar
        $bear2 $snake1 $snake2 $snake3 $fox $puma $ogre_male_1 $goblin_male_1 $orc_male_1
        $orc_female_1 $skeleton $gargoyle1 $gargoyle2 $gargoyle3 $troll $chimeran_wolf_mountain
        $gnome_female $gnome_male $orchan_female $orchan_male $draegoni_female $draegoni_male
        $skunk_1 $racoon_1 $unicorn_1 $chimeran_wolf_desert $chimeran_wolf_forest $bear_3
        $bear_4 $panther $feran $leopard_1 $leopard_2 $chimeran_wolf_arctic $tiger_1
        $tiger_2 $armed_female_orc $armed_male_orc $armed_skeleton $phantom_warrior $imp
        $brownie $leprechaun $spider_s_1 $spider_s_2 $spider_s_3 $spider_l_1 $spider_l_2
        $spider_l_3 $wood_sprite $spider_l_4 $spider_s_4 $giant_1 $hobgoblin $yeti $snake4 
    )],
    CapeTypes => [qw(
        $CAPE_BLACK $CAPE_BLUE $CAPE_BLUEGRAY $CAPE_BROWN $CAPE_BROWNGRAY $CAPE_GRAY
        $CAPE_GREEN $CAPE_GREENGRAY $CAPE_PURPLE $CAPE_WHITE $CAPE_FUR $CAPE_GOLD
        $CAPE_RED $CAPE_ORANGE $CAPE_MOD $CAPE_DERIN $CAPE_RAVENOD $CAPE_PLACID
        $CAPE_LORD_VERMOR $CAPE_AISLINN $CAPE_SOLDUS $CAPE_LOTHARION $CAPE_LEARNER
        $CAPE_NONE
    )],
    ShirtTypes => [qw(
        $SHIRT_BLACK $SHIRT_BLUE $SHIRT_BROWN $SHIRT_GREY $SHIRT_GREEN $SHIRT_LIGHTBROWN
        $SHIRT_ORANGE $SHIRT_PINK $SHIRT_PURPLE $SHIRT_RED $SHIRT_WHITE $SHIRT_YELLOW
        $SHIRT_LEATHER_ARMOR $SHIRT_CHAIN_ARMOR $SHIRT_STEEL_CHAIN_ARMOR $SHIRT_TITANIUM_CHAIN_ARMOR
        $SHIRT_IRON_PLATE_ARMOR $SHIRT_ARMOR_6 $SHIRT_FUR $SHIRT_STEEL_PLATE_ARMOR
        $SHIRT_TITANIUM_PLATE_ARMOR
   )],
   ActorCommands => [qw(
       $nothing $kill_me $die1 $die2 $pain1 $pick $drop $idle $harvest $cast $ranged
       $meele $sit_down $stand_up $turn_left $turn_right $pain2 $enter_combat $leave_combat
       $move_n $move_ne $move_e $move_se $move_s $move_sw $move_w $move_nw $run_n $run_ne
       $run_e $run_se $run_s $run_sw $run_w $run_nw $turn_n $turn_ne $turn_e $turn_se $turn_s
       $turn_sw $turn_w $turn_nw $attack_up_1 $attack_up_2 $attack_up_3 $attack_up_4
       $attack_down_1 $attack_down_2
    )],
    ClientCommands => [qw(
        $RAW_TEXT $ADD_NEW_ACTOR $ADD_ACTOR_COMMAND $YOU_ARE $SYNC_CLOCK $NEW_MINUTE
        $REMOVE_ACTOR $CHANGE_MAP $COMBAT_MODE $KILL_ALL_ACTORS $GET_TELEPORTERS_LIST
        $PONG $TELEPORT_IN $TELEPORT_OUT $PLAY_SOUND $START_RAIN $STOP_RAIN $THUNDER
        $HERE_YOUR_STATS $HERE_YOUR_INVENTORY $INVENTORY_ITEM_TEXT $GET_NEW_INVENTORY_ITEM
        $REMOVE_ITEM_FROM_INVENTORY $HERE_YOUR_GROUND_ITEMS $GET_NEW_GROUND_ITEM
        $REMOVE_ITEM_FROM_GROUND $CLOSE_BAG $GET_NEW_BAG $GET_BAGS_LIST $DESTROY_BAG $NPC_TEXT
        $NPC_OPTIONS_LIST $CLOSE_NPC_MENU $SEND_NPC_INFO $GET_TRADE_INFO $GET_TRADE_OBJECT
        $GET_TRADE_ACCEPT $GET_TRADE_REJECT $GET_TRADE_EXIT $REMOVE_TRADE_OBJECT $GET_YOUR_TRADEOBJECTS
        $GET_TRADE_PARTNER_NAME $GET_YOUR_SIGILS $SPELL_ITEM_TEXT $GET_ACTIVE_SPELL
        $GET_ACTIVE_SPELL_LIST $REMOVE_ACTIVE_SPELL $GET_ACTOR_DAMAGE $GET_ACTOR_HEAL $SEND_PARTIAL_STAT
        $SPAWN_BAG_PARTICLES $ADD_NEW_ENHANCED_ACTOR $ACTOR_WEAR_ITEM $ACTOR_UNWEAR_ITEM $PLAY_MUSIC
        $GET_KNOWLEDGE_LIST $GET_NEW_KNOWLEDGE $GET_KNOWLEDGE_TEXT $BUDDY_EVENT $PING_REQUEST
        $FIRE_PARTICLES $REMOVE_FIRE_AT $DISPLAY_CLIENT_WINDOW $OPEN_BOOK $READ_BOOK $CLOSE_BOOK
        $STORAGE_LIST $STORAGE_ITEMS $STORAGE_TEXT $SPELL_CAST $GET_ACTIVE_CHANNELS $MAP_FLAGS
        $GET_ACTOR_HEALTH $GET_3D_OBJ_LIST $GET_3D_OBJ $REMOVE_3D_OBJ $GET_ITEMS_COOLDOWN $SEND_BUFFS
        $MAP_SET_OBJECTS $MAP_STATE_OBJECTS $UPGRADE_NEW_VERSION $UPGRADE_TOO_OLD $REDEFINE_YOUR_COLORS
        $YOU_DONT_EXIST $LOG_IN_OK $LOG_IN_NOT_OK $CREATE_CHAR_OK $CREATE_CHAR_NOT_OK $BYE
    )],
    ServerCommands => [qw(
        $MOVE_TO $SEND_PM $GET_PLAYER_INFO $RUN_TO $SIT_DOWN $SEND_ME_MY_ACTORS $SEND_OPENING_SCREEN
        $SEND_VERSION $TURN_LEFT $TURN_RIGHT $PING $HEART_BEAT $LOCATE_ME $USE_MAP_OBJECT $SEND_MY_STATS
        $SEND_MY_INVENTORY $LOOK_AT_INVENTORY_ITEM $MOVE_INVENTORY_ITEM $HARVEST $DROP_ITEM
        $PICK_UP_ITEM $LOOK_AT_GROUND_ITEM $INSPECT_BAG $S_CLOSE_BAG $LOOK_AT_MAP_OBJECT $TOUCH_PLAYER
        $RESPOND_TO_NPC $MANUFACTURE_THIS $USE_INVENTORY_ITEM $TRADE_WITH $ACCEPT_TRADE $REJECT_TRADE
        $EXIT_TRADE $PUT_OBJECT_ON_TRADE $REMOVE_OBJECT_FROM_TRADE $LOOK_AT_TRADE_ITEM $CAST_SPELL
        $ATTACK_SOMEONE $GET_KNOWLEDGE_INFO $ITEM_ON_ITEM $SEND_BOOK $GET_STORAGE_CATEGORY
        $DEPOSITE_ITEM $WITHDRAW_ITEM $LOOK_AT_STORAGE_ITEM $SPELL_NAME $PING_RESPONSE
        $SET_ACTIVE_CHANNEL $LOG_IN $CREATE_CHAR $GET_DATE $GET_TIME $SERVER_STATS $ORIGINAL_IP
    )],

    Weapons => [qw(
        $WEAPON_NONE $SWORD_1 $SWORD_2 $SWORD_3 $SWORD_4 $SWORD_5 $SWORD_6 $SWORD_7 $STAFF_1 $STAFF_2
        $STAFF_3 $STAFF_4 $HAMMER_1 $HAMMER_2 $PICKAX $SWORD_1_FIRE $SWORD_2_FIRE $SWORD_2_COLD
        $SWORD_3_FIRE $SWORD_3_COLD $SWORD_3_MAGIC $SWORD_4_FIRE $SWORD_4_COLD $SWORD_4_MAGIC
        $SWORD_4_THERMAL $SWORD_5_FIRE $SWORD_5_COLD $SWORD_5_MAGIC $SWORD_5_THERMAL $SWORD_6_FIRE
        $SWORD_6_COLD $SWORD_6_MAGIC $SWORD_6_THERMAL $SWORD_7_FIRE $SWORD_7_COLD $SWORD_7_MAGIC
        $SWORD_7_THERMAL $PICKAX_MAGIC $BATTLEAXE_IRON $BATTLEAXE_STEEL $BATTLEAXE_TITANIUM
        $BATTLEAXE_IRON_FIRE $BATTLEAXE_STEEL_COLD $BATTLEAXE_STEEL_FIRE $BATTLEAXE_TITANIUM_COLD
        $BATTLEAXE_TITANIUM_FIRE $BATTLEAXE_TITANIUM_MAGIC $GLOVE_FUR $GLOVE_LEATHER $BONE_1
        $STICK_1 $SWORD_EMERALD_CLAYMORE $SWORD_CUTLASS $SWORD_SUNBREAKER $SWORD_ORC_SLAYER
        $SWORD_EAGLE_WING $SWORD_RAPIER $SWORD_JAGGED_SABER
    )],
    Stats => [qw(
        $PHY_CUR $PHY_BASE $COO_CUR $COO_BASE $REAS_CUR $REAS_BASE $WILL_CUR $WILL_BASE $INST_CUR
        $INST_BASE $VIT_CUR $VIT_BASE $HUMAN_CUR $HUMAN_BASE $ANIMAL_CUR $ANIMAL_BASE $VEGETAL_CUR
        $VEGETAL_BASE $INORG_CUR $INORG_BASE $ARTIF_CUR $ARTIF_BASE $MAGIC_CUR $MAGIC_BASE $MAN_S_CUR
        $MAN_S_BASE $HARV_S_CUR $HARV_S_BASE $ALCH_S_CUR $ALCH_S_BASE $OVRL_S_CUR $OVRL_S_BASE $DEF_S_CUR
        $DEF_S_BASE $ATT_S_CUR $ATT_S_BASE $MAG_S_CUR $MAG_S_BASE $POT_S_CUR $POT_S_BASE $CARRY_WGHT_CUR
        $CARRY_WGHT_BASE $MAT_POINT_CUR $MAT_POINT_BASE $ETH_POINT_CUR $ETH_POINT_BASE $FOOD_LEV $RESEARCHING
        $MAG_RES $MAN_EXP $MAN_EXP_NEXT $HARV_EXP $HARV_EXP_NEXT $ALCH_EXP $ALCH_EXP_NEXT $OVRL_EXP
        $OVRL_EXP_NEXT $DEF_EXP $DEF_EXP_NEXT $ATT_EXP $ATT_EXP_NEXT $MAG_EXP $MAG_EXP_NEXT $POT_EXP
        $POT_EXP_NEXT $RESEARCH_COMPLETED $RESEARCH_TOTAL $SUM_EXP $SUM_EXP_NEXT $SUM_S_CUR $SUM_S_BASE
        $CRA_EXP $CRA_EXP_NEXT $CRA_S_CUR $CRA_S_BASE
    )],
);

our $DEBUG_PACKETS   = 1;
our $DEBUG_TYPES     = 2;
our $DEBUG_PATH      = 4;
our $DEBUG_TEXT      = 8;
our $DEBUG_BAGS      = 16;

our $KIND_OF_WEAPON = chr(0);
our $KIND_OF_SHIELD = chr(1);
our $KIND_OF_CAPE = chr(2);
our $KIND_OF_HELMET = chr(3);
our $KIND_OF_LEG_ARMOR = chr(4);
our $KIND_OF_BODY_ARMOR = chr(5);
our $KIND_OF_BOOT_ARMOR = chr(6);

our $CHAT_LOCAL = chr(0);
our $CHAT_PERSONAL = chr(1);
our $CHAT_GM = chr(2);
our $CHAT_SERVER = chr(3);
our $CHAT_MOD = chr(4);
our $CHAT_CHANNEL1 = chr(5);
our $CHAT_CHANNEL2 = chr(6);
our $CHAT_CHANNEL3 = chr(7);
our $CHAT_MODPM = chr(8);

our $SKIN_BROWN = chr(0);
our $SKIN_NORMAL = chr(1);
our $SKIN_PALE = chr(2);
our $SKIN_TAN = chr(3);
our $SKIN_DARK_BLUE = chr(4);

our $HELMET_IRON = chr(0);
our $HELMET_FUR = chr(1);
our $HELMET_LEATHER = chr(2);
our $HELMET_RACOON = chr(3);
our $HELMET_SKUNK = chr(4);
our $HELMET_CROWN_OF_MANA = chr(5);
our $HELMET_CROWN_OF_LIFE = chr(6);
our $HELMET_STEEL = chr(7);
our $HELMET_TITANIUM = chr(8);
our $HELMET_HYDROGENIUM = chr(9);
our $HELMET_NONE = chr(20);

our $HEAD_1 = chr(0);
our $HEAD_2 = chr(1);
our $HEAD_3 = chr(2);
our $HEAD_4 = chr(3);
our $HEAD_5 = chr(4);

our $CAPE_BLACK = chr(0);
our $CAPE_BLUE = chr(1);
our $CAPE_BLUEGRAY = chr(2);
our $CAPE_BROWN = chr(3);
our $CAPE_BROWNGRAY = chr(4);
our $CAPE_GRAY = chr(5);
our $CAPE_GREEN = chr(6);
our $CAPE_GREENGRAY = chr(7);
our $CAPE_PURPLE = chr(8);
our $CAPE_WHITE = chr(9);
our $CAPE_FUR = chr(10);
our $CAPE_GOLD = chr(11);
our $CAPE_RED = chr(12);
our $CAPE_ORANGE = chr(13);
our $CAPE_MOD = chr(14);
our $CAPE_DERIN = chr(15);
our $CAPE_RAVENOD = chr(16);
our $CAPE_PLACID = chr(17);
our $CAPE_LORD_VERMOR = chr(18);
our $CAPE_AISLINN = chr(19);
our $CAPE_SOLDUS = chr(20);
our $CAPE_LOTHARION = chr(21);
our $CAPE_LEARNER = chr(22);
our $CAPE_NONE = chr(30);

our $RAW_TEXT = chr(0);
our $ADD_NEW_ACTOR = chr(1);
our $ADD_ACTOR_COMMAND = chr(2);
our $YOU_ARE = chr(3);
our $SYNC_CLOCK = chr(4);
our $NEW_MINUTE = chr(5);
our $REMOVE_ACTOR = chr(6);
our $CHANGE_MAP = chr(7);
our $COMBAT_MODE = chr(8);
our $KILL_ALL_ACTORS = chr(9);
our $GET_TELEPORTERS_LIST = chr(10);
our $PONG = chr(11);
our $TELEPORT_IN = chr(12);
our $TELEPORT_OUT = chr(13);
our $PLAY_SOUND = chr(14);
our $START_RAIN = chr(15);
our $STOP_RAIN = chr(16);
our $THUNDER = chr(17);
our $HERE_YOUR_STATS = chr(18);
our $HERE_YOUR_INVENTORY = chr(19);
our $INVENTORY_ITEM_TEXT = chr(20);
our $GET_NEW_INVENTORY_ITEM = chr(21);
our $REMOVE_ITEM_FROM_INVENTORY = chr(22);
our $HERE_YOUR_GROUND_ITEMS = chr(23);
our $GET_NEW_GROUND_ITEM = chr(24);
our $REMOVE_ITEM_FROM_GROUND = chr(25);
our $CLOSE_BAG = chr(26);
our $GET_NEW_BAG = chr(27);
our $GET_BAGS_LIST = chr(28);
our $DESTROY_BAG = chr(29);
our $NPC_TEXT = chr(30);
our $NPC_OPTIONS_LIST = chr(31);
our $CLOSE_NPC_MENU = chr(32);
our $SEND_NPC_INFO = chr(33);
our $GET_TRADE_INFO = chr(34);
our $GET_TRADE_OBJECT = chr(35);
our $GET_TRADE_ACCEPT = chr(36);
our $GET_TRADE_REJECT = chr(37);
our $GET_TRADE_EXIT = chr(38);
our $REMOVE_TRADE_OBJECT = chr(39);
our $GET_YOUR_TRADEOBJECTS = chr(40);
our $GET_TRADE_PARTNER_NAME = chr(41);
our $GET_YOUR_SIGILS = chr(42);
our $SPELL_ITEM_TEXT = chr(43);
our $GET_ACTIVE_SPELL = chr(44);
our $GET_ACTIVE_SPELL_LIST = chr(45);
our $REMOVE_ACTIVE_SPELL = chr(46);
our $GET_ACTOR_DAMAGE = chr(47);
our $GET_ACTOR_HEAL = chr(48);
our $SEND_PARTIAL_STAT = chr(49);
our $SPAWN_BAG_PARTICLES = chr(50);
our $ADD_NEW_ENHANCED_ACTOR = chr(51);
our $ACTOR_WEAR_ITEM = chr(52);
our $ACTOR_UNWEAR_ITEM = chr(53);
our $PLAY_MUSIC = chr(54);
our $GET_KNOWLEDGE_LIST = chr(55);
our $GET_NEW_KNOWLEDGE = chr(56);
our $GET_KNOWLEDGE_TEXT = chr(57);
our $BUDDY_EVENT = chr(59);
our $PING_REQUEST = chr(60);
our $FIRE_PARTICLES = chr(61);
our $REMOVE_FIRE_AT = chr(62);
our $DISPLAY_CLIENT_WINDOW = chr(63);
our $OPEN_BOOK = chr(64);
our $READ_BOOK = chr(65);
our $CLOSE_BOOK = chr(66);
our $STORAGE_LIST = chr(67);
our $STORAGE_ITEMS = chr(68);
our $STORAGE_TEXT = chr(69);
our $SPELL_CAST = chr(70);
our $GET_ACTIVE_CHANNELS = chr(71);
our $MAP_FLAGS = chr(72);
our $GET_ACTOR_HEALTH = chr(73);
our $GET_3D_OBJ_LIST = chr(74);
our $GET_3D_OBJ = chr(75);
our $REMOVE_3D_OBJ = chr(76);
our $GET_ITEMS_COOLDOWN = chr(77);
our $SEND_BUFFS = chr(78);
our $MAP_SET_OBJECTS = chr(220);
our $MAP_STATE_OBJECTS = chr(221);
our $UPGRADE_NEW_VERSION = chr(240);
our $UPGRADE_TOO_OLD = chr(241);
our $REDEFINE_YOUR_COLORS = chr(248);
our $YOU_DONT_EXIST = chr(249);
our $LOG_IN_OK = chr(250);
our $LOG_IN_NOT_OK = chr(251);
our $CREATE_CHAR_OK = chr(252);
our $CREATE_CHAR_NOT_OK = chr(253);
our $BYE = chr(255);

our $NO_BODY_ARMOR = chr(0);
our $NO_PANTS_ARMOR = chr(0);
our $NO_BOOTS_ARMOR = chr(0);

our $MOVE_TO = chr(1);
our $SEND_PM = chr(2);
our $GET_PLAYER_INFO = chr(5);
our $RUN_TO = chr(6);
our $SIT_DOWN = chr(7);
our $SEND_ME_MY_ACTORS = chr(8);
our $SEND_OPENING_SCREEN = chr(9);
our $SEND_VERSION = chr(10);
our $TURN_LEFT = chr(11);
our $TURN_RIGHT = chr(12);
our $PING = chr(13);
our $HEART_BEAT = chr(14);
our $LOCATE_ME = chr(15);
our $USE_MAP_OBJECT = chr(16);
our $SEND_MY_STATS = chr(17);
our $SEND_MY_INVENTORY = chr(18);
our $LOOK_AT_INVENTORY_ITEM = chr(19);
our $MOVE_INVENTORY_ITEM = chr(20);
our $HARVEST = chr(21);
our $DROP_ITEM = chr(22);
our $PICK_UP_ITEM = chr(23);
our $LOOK_AT_GROUND_ITEM = chr(24);
our $INSPECT_BAG = chr(25);
our $S_CLOSE_BAG = chr(26);
our $LOOK_AT_MAP_OBJECT = chr(27);
our $TOUCH_PLAYER = chr(28);
our $RESPOND_TO_NPC = chr(29);
our $MANUFACTURE_THIS = chr(30);
our $USE_INVENTORY_ITEM = chr(31);
our $TRADE_WITH = chr(32);
our $ACCEPT_TRADE = chr(33);
our $REJECT_TRADE = chr(34);
our $EXIT_TRADE = chr(35);
our $PUT_OBJECT_ON_TRADE = chr(36);
our $REMOVE_OBJECT_FROM_TRADE = chr(37);
our $LOOK_AT_TRADE_ITEM = chr(38);
our $CAST_SPELL = chr(39);
our $ATTACK_SOMEONE = chr(40);
our $GET_KNOWLEDGE_INFO = chr(41);
our $ITEM_ON_ITEM = chr(42);
our $SEND_BOOK = chr(43);
our $GET_STORAGE_CATEGORY = chr(44);
our $DEPOSITE_ITEM = chr(45);
our $WITHDRAW_ITEM = chr(46);
our $LOOK_AT_STORAGE_ITEM = chr(47);
our $SPELL_NAME = chr(48);
our $PING_RESPONSE = chr(60);
our $SET_ACTIVE_CHANNEL = chr(61);
our $LOG_IN = chr(140);
our $CREATE_CHAR = chr(141);
our $GET_DATE = chr(230);
our $GET_TIME = chr(231);
our $SERVER_STATS = chr(232);
our $ORIGINAL_IP = chr(233);

our $PHY_CUR = chr(0);
our $PHY_BASE = chr(1);
our $COO_CUR = chr(2);
our $COO_BASE = chr(3);
our $REAS_CUR = chr(4);
our $REAS_BASE = chr(5);
our $WILL_CUR = chr(6);
our $WILL_BASE = chr(7);
our $INST_CUR = chr(8);
our $INST_BASE = chr(9);
our $VIT_CUR = chr(10);
our $VIT_BASE = chr(11);
our $HUMAN_CUR = chr(12);
our $HUMAN_BASE = chr(13);
our $ANIMAL_CUR = chr(14);
our $ANIMAL_BASE = chr(15);
our $VEGETAL_CUR = chr(16);
our $VEGETAL_BASE = chr(17);
our $INORG_CUR = chr(18);
our $INORG_BASE = chr(19);
our $ARTIF_CUR = chr(20);
our $ARTIF_BASE = chr(21);
our $MAGIC_CUR = chr(22);
our $MAGIC_BASE = chr(23);
our $MAN_S_CUR = chr(24);
our $MAN_S_BASE = chr(25);
our $HARV_S_CUR = chr(26);
our $HARV_S_BASE = chr(27);
our $ALCH_S_CUR = chr(28);
our $ALCH_S_BASE = chr(29);
our $OVRL_S_CUR = chr(30);
our $OVRL_S_BASE = chr(31);
our $DEF_S_CUR = chr(32);
our $DEF_S_BASE = chr(33);
our $ATT_S_CUR = chr(34);
our $ATT_S_BASE = chr(35);
our $MAG_S_CUR = chr(36);
our $MAG_S_BASE = chr(37);
our $POT_S_CUR = chr(38);
our $POT_S_BASE = chr(39);
our $CARRY_WGHT_CUR = chr(40);
our $CARRY_WGHT_BASE = chr(41);
our $MAT_POINT_CUR = chr(42);
our $MAT_POINT_BASE = chr(43);
our $ETH_POINT_CUR = chr(44);
our $ETH_POINT_BASE = chr(45);
our $FOOD_LEV = chr(46);
our $RESEARCHING = chr(47);
our $MAG_RES = chr(48);
our $MAN_EXP = chr(49);
our $MAN_EXP_NEXT = chr(50);
our $HARV_EXP = chr(51);
our $HARV_EXP_NEXT = chr(52);
our $ALCH_EXP = chr(53);
our $ALCH_EXP_NEXT = chr(54);
our $OVRL_EXP = chr(55);
our $OVRL_EXP_NEXT = chr(56);
our $DEF_EXP = chr(57);
our $DEF_EXP_NEXT = chr(58);
our $ATT_EXP = chr(59);
our $ATT_EXP_NEXT = chr(60);
our $MAG_EXP = chr(61);
our $MAG_EXP_NEXT = chr(62);
our $POT_EXP = chr(63);
our $POT_EXP_NEXT = chr(64);
our $RESEARCH_COMPLETED = chr(65);
our $RESEARCH_TOTAL = chr(66);
our $SUM_EXP = chr(67);
our $SUM_EXP_NEXT = chr(68);
our $SUM_S_CUR = chr(69);
our $SUM_S_BASE = chr(70);
our $CRA_EXP = chr(71);
our $CRA_EXP_NEXT = chr(72);
our $CRA_S_CUR = chr(73);
our $CRA_S_BASE = chr(74);

our $frame_walk = chr(0);
our $frame_run = chr(1);
our $frame_die1 = chr(2);
our $frame_die2 = chr(3);
our $frame_pain1 = chr(4);
our $frame_pick = chr(5);
our $frame_drop = chr(6);
our $frame_idle = chr(7);
our $frame_harvest = chr(8);
our $frame_cast = chr(9);
our $frame_ranged = chr(10);
our $frame_pain2 = chr(11);
our $frame_sit = chr(12);
our $frame_stand = chr(13);
our $frame_sit_idle = chr(14);
our $frame_combat_idle = chr(15);
our $frame_in_combat = chr(16);
our $frame_out_combat = chr(17);
our $frame_attack_up_1 = chr(18);
our $frame_attack_up_2 = chr(19);
our $frame_attack_up_3 = chr(20);
our $frame_attack_up_4 = chr(21);
our $frame_attack_down_1 = chr(22);
our $frame_attack_down_2 = chr(23);

our $human_female = chr(0);
our $human_male = chr(1);
our $elf_female = chr(2);
our $elf_male = chr(3);
our $dwarf_female = chr(4);
our $dwarf_male = chr(5);
our $wraith = chr(6);
our $cyclops = chr(7);
our $beaver = chr(8);
our $rat = chr(9);
our $goblin_male_2 = chr(10);
our $goblin_female_1 = chr(11);
our $town_folk4 = chr(12);
our $town_folk5 = chr(13);
our $shop_girl3 = chr(14);
our $deer = chr(15);
our $bear = chr(16);
our $wolf = chr(17);
our $white_rabbit = chr(18);
our $brown_rabbit = chr(19);
our $boar = chr(20);
our $bear2 = chr(21);
our $snake1 = chr(22);
our $snake2 = chr(23);
our $snake3 = chr(24);
our $fox = chr(25);
our $puma = chr(26);
our $ogre_male_1 = chr(27);
our $goblin_male_1 = chr(28);
our $orc_male_1 = chr(29);
our $orc_female_1 = chr(30);
our $skeleton = chr(31);
our $gargoyle1 = chr(32);
our $gargoyle2 = chr(33);
our $gargoyle3 = chr(34);
our $troll = chr(35);
our $chimeran_wolf_mountain = chr(36);
our $gnome_female = chr(37);
our $gnome_male = chr(38);
our $orchan_female = chr(39);
our $orchan_male = chr(40);
our $draegoni_female = chr(41);
our $draegoni_male = chr(42);
our $skunk_1 = chr(43);
our $racoon_1 = chr(44);
our $unicorn_1 = chr(45);
our $chimeran_wolf_desert = chr(46);
our $chimeran_wolf_forest = chr(47);
our $bear_3 = chr(48);
our $bear_4 = chr(49);
our $panther = chr(50);
our $feran = chr(51);
our $leopard_1 = chr(52);
our $leopard_2 = chr(53);
our $chimeran_wolf_arctic = chr(54);
our $tiger_1 = chr(55);
our $tiger_2 = chr(56);
our $armed_female_orc = chr(57);
our $armed_male_orc = chr(58);
our $armed_skeleton = chr(59);
our $phantom_warrior = chr(60);
our $imp = chr(61);
our $brownie = chr(62);
our $leprechaun = chr(63);
our $spider_s_1 = chr(64);
our $spider_s_2 = chr(65);
our $spider_s_3 = chr(66);
our $spider_l_1 = chr(67);
our $spider_l_2 = chr(68);
our $spider_l_3 = chr(69);
our $wood_sprite = chr(70);
our $spider_l_4 = chr(71);
our $spider_s_4 = chr(72);
our $giant_1 = chr(73);
our $hobgoblin = chr(74);
our $yeti = chr(75);
our $snake4 = chr(76);

our $WEAPON_NONE = chr(0);
our $SWORD_1 = chr(1);
our $SWORD_2 = chr(2);
our $SWORD_3 = chr(3);
our $SWORD_4 = chr(4);
our $SWORD_5 = chr(5);
our $SWORD_6 = chr(6);
our $SWORD_7 = chr(7);
our $STAFF_1 = chr(8);
our $STAFF_2 = chr(9);
our $STAFF_3 = chr(10);
our $STAFF_4 = chr(11);
our $HAMMER_1 = chr(12);
our $HAMMER_2 = chr(13);
our $PICKAX = chr(14);
our $SWORD_1_FIRE = chr(15);
our $SWORD_2_FIRE = chr(16);
our $SWORD_2_COLD = chr(17);
our $SWORD_3_FIRE = chr(18);
our $SWORD_3_COLD = chr(19);
our $SWORD_3_MAGIC = chr(20);
our $SWORD_4_FIRE = chr(21);
our $SWORD_4_COLD = chr(22);
our $SWORD_4_MAGIC = chr(23);
our $SWORD_4_THERMAL = chr(24);
our $SWORD_5_FIRE = chr(25);
our $SWORD_5_COLD = chr(26);
our $SWORD_5_MAGIC = chr(27);
our $SWORD_5_THERMAL = chr(28);
our $SWORD_6_FIRE = chr(29);
our $SWORD_6_COLD = chr(30);
our $SWORD_6_MAGIC = chr(31);
our $SWORD_6_THERMAL = chr(32);
our $SWORD_7_FIRE = chr(33);
our $SWORD_7_COLD = chr(34);
our $SWORD_7_MAGIC = chr(35);
our $SWORD_7_THERMAL = chr(36);
our $PICKAX_MAGIC = chr(37);
our $BATTLEAXE_IRON = chr(38);
our $BATTLEAXE_STEEL = chr(39);
our $BATTLEAXE_TITANIUM = chr(40);
our $BATTLEAXE_IRON_FIRE = chr(41);
our $BATTLEAXE_STEEL_COLD = chr(42);
our $BATTLEAXE_STEEL_FIRE = chr(43);
our $BATTLEAXE_TITANIUM_COLD = chr(44);
our $BATTLEAXE_TITANIUM_FIRE = chr(45);
our $BATTLEAXE_TITANIUM_MAGIC = chr(46);
our $GLOVE_FUR = chr(47);
our $GLOVE_LEATHER = chr(48);
our $BONE_1 = chr(49);
our $STICK_1 = chr(50);
our $SWORD_EMERALD_CLAYMORE = chr(51);
our $SWORD_CUTLASS = chr(52);
our $SWORD_SUNBREAKER = chr(53);
our $SWORD_ORC_SLAYER = chr(54);
our $SWORD_EAGLE_WING = chr(55);
our $SWORD_RAPIER = chr(56);
our $SWORD_JAGGED_SABER = chr(57);

our $PANTS_BLACK = chr(0);
our $PANTS_BLUE = chr(1);
our $PANTS_BROWN = chr(2);
our $PANTS_DARKBROWN = chr(3);
our $PANTS_GREY = chr(4);
our $PANTS_GREEN = chr(5);
our $PANTS_LIGHTBROWN = chr(6);
our $PANTS_RED = chr(7);
our $PANTS_WHITE = chr(8);
our $PANTS_LEATHER = chr(9);
our $PANTS_IRON_CUISSES = chr(10);
our $PANTS_FUR = chr(11);
our $PANTS_STEEL_CUISSES = chr(12);
our $PANTS_TITANIUM_CUISSES = chr(13);
our $PANTS_HYDROGENIUM_CUISSES = chr(14);

our $RULE_WIN = chr(1);
our $RULE_INTERFACE = chr(2);
our $NEW_CHAR_INTERFACE = chr(3);

our $nothing = chr(0);
our $kill_me = chr(1);
our $die1 = chr(3);
our $die2 = chr(4);
our $pain1 = chr(5);
our $pick = chr(6);
our $drop = chr(7);
our $idle = chr(8);
our $harvest = chr(9);
our $cast = chr(10);
our $ranged = chr(11);
our $meele = chr(12);
our $sit_down = chr(13);
our $stand_up = chr(14);
our $turn_left = chr(15);
our $turn_right = chr(16);
our $pain2 = chr(17);
our $enter_combat = chr(18);
our $leave_combat = chr(19);
our $move_n = chr(20);
our $move_ne = chr(21);
our $move_e = chr(22);
our $move_se = chr(23);
our $move_s = chr(24);
our $move_sw = chr(25);
our $move_w = chr(26);
our $move_nw = chr(27);
our $run_n = chr(30);
our $run_ne = chr(31);
our $run_e = chr(32);
our $run_se = chr(33);
our $run_s = chr(34);
our $run_sw = chr(35);
our $run_w = chr(36);
our $run_nw = chr(37);
our $turn_n = chr(38);
our $turn_ne = chr(39);
our $turn_e = chr(40);
our $turn_se = chr(41);
our $turn_s = chr(42);
our $turn_sw = chr(43);
our $turn_w = chr(44);
our $turn_nw = chr(45);
our $attack_up_1 = chr(46);
our $attack_up_2 = chr(47);
our $attack_up_3 = chr(48);
our $attack_up_4 = chr(49);
our $attack_down_1 = chr(50);
our $attack_down_2 = chr(51);

our $BOOTS_BLACK = chr(0);
our $BOOTS_BROWN = chr(1);
our $BOOTS_DARKBROWN = chr(2);
our $BOOTS_DULLBROWN = chr(3);
our $BOOTS_LIGHTBROWN = chr(4);
our $BOOTS_ORANGE = chr(5);
our $BOOTS_LEATHER = chr(6);
our $BOOTS_FUR = chr(7);
our $BOOTS_IRON_GREAVE = chr(8);
our $BOOTS_STEEL_GREAVE = chr(9);
our $BOOTS_TITANIUM_GREAVE = chr(10);
our $BOOTS_HYDROGENIUM_GREAVE = chr(11);

our $snd_rain = chr(0);
our $snd_tele_in = chr(1);
our $snd_tele_out = chr(2);
our $snd_teleprtr = chr(3);
our $snd_thndr_1 = chr(4);
our $snd_thndr_2 = chr(5);
our $snd_thndr_3 = chr(6);
our $snd_thndr_4 = chr(7);
our $snd_thndr_5 = chr(8);
our $snd_fire = chr(9);

our $c_lbound = chr(0);
our $c_red1 = chr(0);
our $c_orange1 = chr(1);
our $c_yellow1 = chr(2);
our $c_green1 = chr(3);
our $c_blue1 = chr(4);
our $c_purple1 = chr(5);
our $c_grey1 = chr(6);
our $c_red2 = chr(7);
our $c_orange2 = chr(8);
our $c_yellow2 = chr(9);
our $c_green2 = chr(10);
our $c_blue2 = chr(11);
our $c_purple2 = chr(12);
our $c_grey2 = chr(13);
our $c_red3 = chr(14);
our $c_orange3 = chr(15);
our $c_yellow3 = chr(16);
our $c_green3 = chr(17);
our $c_blue3 = chr(18);
our $c_purple3 = chr(19);
our $c_grey3 = chr(20);
our $c_red4 = chr(21);
our $c_orange4 = chr(22);
our $c_yellow4 = chr(23);
our $c_green4 = chr(24);
our $c_blue4 = chr(25);
our $c_purple4 = chr(26);
our $c_ubound = chr(27);
our $c_grey4 = chr(27);

our $SHIRT_BLACK = chr(0);
our $SHIRT_BLUE = chr(1);
our $SHIRT_BROWN = chr(2);
our $SHIRT_GREY = chr(3);
our $SHIRT_GREEN = chr(4);
our $SHIRT_LIGHTBROWN = chr(5);
our $SHIRT_ORANGE = chr(6);
our $SHIRT_PINK = chr(7);
our $SHIRT_PURPLE = chr(8);
our $SHIRT_RED = chr(9);
our $SHIRT_WHITE = chr(10);
our $SHIRT_YELLOW = chr(11);
our $SHIRT_LEATHER_ARMOR = chr(12);
our $SHIRT_CHAIN_ARMOR = chr(13);
our $SHIRT_STEEL_CHAIN_ARMOR = chr(14);
our $SHIRT_TITANIUM_CHAIN_ARMOR = chr(15);
our $SHIRT_IRON_PLATE_ARMOR = chr(16);
our $SHIRT_ARMOR_6 = chr(17);
our $SHIRT_FUR = chr(18);
our $SHIRT_STEEL_PLATE_ARMOR = chr(19);
our $SHIRT_TITANIUM_PLATE_ARMOR = chr(20);

our $HAIR_BLACK = chr(0);
our $HAIR_BLOND = chr(1);
our $HAIR_BROWN = chr(2);
our $HAIR_GRAY = chr(3);
our $HAIR_RED = chr(4);
our $HAIR_WHITE = chr(5);
our $HAIR_BLUE = chr(6);
our $HAIR_GREEN = chr(7);
our $HAIR_PURPLE = chr(8);

our $SHIELD_WOOD = chr(0);
our $SHIELD_WOOD_ENHANCED = chr(1);
our $SHIELD_IRON = chr(2);
our $SHIELD_STEEL = chr(3);
our $SHIELD_TITANIUM = chr(4);
our $SHIELD_HYDROGENIUM = chr(5);
our $SHIELD_NONE = chr(11);

our %WearableItemsByID = (
   chr(0) => 'KIND_OF_WEAPON',
   chr(1) => 'KIND_OF_SHIELD',
   chr(2) => 'KIND_OF_CAPE',
   chr(3) => 'KIND_OF_HELMET',
   chr(4) => 'KIND_OF_LEG_ARMOR',
   chr(5) => 'KIND_OF_BODY_ARMOR',
   chr(6) => 'KIND_OF_BOOT_ARMOR',
);

our %TextChannelsByID = (
   chr(0) => 'CHAT_LOCAL',
   chr(1) => 'CHAT_PERSONAL',
   chr(2) => 'CHAT_GM',
   chr(3) => 'CHAT_SERVER',
   chr(4) => 'CHAT_MOD',
   chr(5) => 'CHAT_CHANNEL1',
   chr(6) => 'CHAT_CHANNEL2',
   chr(7) => 'CHAT_CHANNEL3',
   chr(8) => 'CHAT_MODPM',
);

our %SkinColorsByID = (
   chr(0) => 'SKIN_BROWN',
   chr(1) => 'SKIN_NORMAL',
   chr(2) => 'SKIN_PALE',
   chr(3) => 'SKIN_TAN',
   chr(4) => 'SKIN_DARK_BLUE',
);

our %HelmetsByID = (
   chr(0) => 'HELMET_IRON',
   chr(1) => 'HELMET_FUR',
   chr(2) => 'HELMET_LEATHER',
   chr(3) => 'HELMET_RACOON',
   chr(4) => 'HELMET_SKUNK',
   chr(5) => 'HELMET_CROWN_OF_MANA',
   chr(6) => 'HELMET_CROWN_OF_LIFE',
   chr(7) => 'HELMET_STEEL',
   chr(8) => 'HELMET_TITANIUM',
   chr(9) => 'HELMET_HYDROGENIUM',
   chr(20) => 'HELMET_NONE',
);

our %HeadsByID = (
   chr(0) => 'HEAD_1',
   chr(1) => 'HEAD_2',
   chr(2) => 'HEAD_3',
   chr(3) => 'HEAD_4',
   chr(4) => 'HEAD_5',
);

our %CapesByID = (
   chr(0) => 'CAPE_BLACK',
   chr(1) => 'CAPE_BLUE',
   chr(2) => 'CAPE_BLUEGRAY',
   chr(3) => 'CAPE_BROWN',
   chr(4) => 'CAPE_BROWNGRAY',
   chr(5) => 'CAPE_GRAY',
   chr(6) => 'CAPE_GREEN',
   chr(7) => 'CAPE_GREENGRAY',
   chr(8) => 'CAPE_PURPLE',
   chr(9) => 'CAPE_WHITE',
   chr(10) => 'CAPE_FUR',
   chr(11) => 'CAPE_GOLD',
   chr(12) => 'CAPE_RED',
   chr(13) => 'CAPE_ORANGE',
   chr(14) => 'CAPE_MOD',
   chr(15) => 'CAPE_DERIN',
   chr(16) => 'CAPE_RAVENOD',
   chr(17) => 'CAPE_PLACID',
   chr(18) => 'CAPE_LORD_VERMOR',
   chr(19) => 'CAPE_AISLINN',
   chr(20) => 'CAPE_SOLDUS',
   chr(21) => 'CAPE_LOTHARION',
   chr(22) => 'CAPE_LEARNER',
   chr(30) => 'CAPE_NONE',
);

our %ClientCommandsByID = (
   chr(0) => 'RAW_TEXT',
   chr(1) => 'ADD_NEW_ACTOR',
   chr(2) => 'ADD_ACTOR_COMMAND',
   chr(3) => 'YOU_ARE',
   chr(4) => 'SYNC_CLOCK',
   chr(5) => 'NEW_MINUTE',
   chr(6) => 'REMOVE_ACTOR',
   chr(7) => 'CHANGE_MAP',
   chr(8) => 'COMBAT_MODE',
   chr(9) => 'KILL_ALL_ACTORS',
   chr(10) => 'GET_TELEPORTERS_LIST',
   chr(11) => 'PONG',
   chr(12) => 'TELEPORT_IN',
   chr(13) => 'TELEPORT_OUT',
   chr(14) => 'PLAY_SOUND',
   chr(15) => 'START_RAIN',
   chr(16) => 'STOP_RAIN',
   chr(17) => 'THUNDER',
   chr(18) => 'HERE_YOUR_STATS',
   chr(19) => 'HERE_YOUR_INVENTORY',
   chr(20) => 'INVENTORY_ITEM_TEXT',
   chr(21) => 'GET_NEW_INVENTORY_ITEM',
   chr(22) => 'REMOVE_ITEM_FROM_INVENTORY',
   chr(23) => 'HERE_YOUR_GROUND_ITEMS',
   chr(24) => 'GET_NEW_GROUND_ITEM',
   chr(25) => 'REMOVE_ITEM_FROM_GROUND',
   chr(26) => 'CLOSE_BAG',
   chr(27) => 'GET_NEW_BAG',
   chr(28) => 'GET_BAGS_LIST',
   chr(29) => 'DESTROY_BAG',
   chr(30) => 'NPC_TEXT',
   chr(31) => 'NPC_OPTIONS_LIST',
   chr(32) => 'CLOSE_NPC_MENU',
   chr(33) => 'SEND_NPC_INFO',
   chr(34) => 'GET_TRADE_INFO',
   chr(35) => 'GET_TRADE_OBJECT',
   chr(36) => 'GET_TRADE_ACCEPT',
   chr(37) => 'GET_TRADE_REJECT',
   chr(38) => 'GET_TRADE_EXIT',
   chr(39) => 'REMOVE_TRADE_OBJECT',
   chr(40) => 'GET_YOUR_TRADEOBJECTS',
   chr(41) => 'GET_TRADE_PARTNER_NAME',
   chr(42) => 'GET_YOUR_SIGILS',
   chr(43) => 'SPELL_ITEM_TEXT',
   chr(44) => 'GET_ACTIVE_SPELL',
   chr(45) => 'GET_ACTIVE_SPELL_LIST',
   chr(46) => 'REMOVE_ACTIVE_SPELL',
   chr(47) => 'GET_ACTOR_DAMAGE',
   chr(48) => 'GET_ACTOR_HEAL',
   chr(49) => 'SEND_PARTIAL_STAT',
   chr(50) => 'SPAWN_BAG_PARTICLES',
   chr(51) => 'ADD_NEW_ENHANCED_ACTOR',
   chr(52) => 'ACTOR_WEAR_ITEM',
   chr(53) => 'ACTOR_UNWEAR_ITEM',
   chr(54) => 'PLAY_MUSIC',
   chr(55) => 'GET_KNOWLEDGE_LIST',
   chr(56) => 'GET_NEW_KNOWLEDGE',
   chr(57) => 'GET_KNOWLEDGE_TEXT',
   chr(59) => 'BUDDY_EVENT',
   chr(60) => 'PING_REQUEST',
   chr(61) => 'FIRE_PARTICLES',
   chr(62) => 'REMOVE_FIRE_AT',
   chr(63) => 'DISPLAY_CLIENT_WINDOW',
   chr(64) => 'OPEN_BOOK',
   chr(65) => 'READ_BOOK',
   chr(66) => 'CLOSE_BOOK',
   chr(67) => 'STORAGE_LIST',
   chr(68) => 'STORAGE_ITEMS',
   chr(69) => 'STORAGE_TEXT',
   chr(70) => 'SPELL_CAST',
   chr(71) => 'GET_ACTIVE_CHANNELS',
   chr(72) => 'MAP_FLAGS',
   chr(73) => 'GET_ACTOR_HEALTH',
   chr(74) => 'GET_3D_OBJ_LIST',
   chr(75) => 'GET_3D_OBJ',
   chr(76) => 'REMOVE_3D_OBJ',
   chr(77) => 'GET_ITEMS_COOLDOWN',
   chr(78) => 'SEND_BUFFS',
   chr(220) => 'MAP_SET_OBJECTS',
   chr(221) => 'MAP_STATE_OBJECTS',
   chr(240) => 'UPGRADE_NEW_VERSION',
   chr(241) => 'UPGRADE_TOO_OLD',
   chr(248) => 'REDEFINE_YOUR_COLORS',
   chr(249) => 'YOU_DONT_EXIST',
   chr(250) => 'LOG_IN_OK',
   chr(251) => 'LOG_IN_NOT_OK',
   chr(252) => 'CREATE_CHAR_OK',
   chr(253) => 'CREATE_CHAR_NOT_OK',
   chr(255) => 'BYE',
);

our %NoArmorFlagsByID = (
   chr(0) => 'NO_BODY_ARMOR',
   chr(0) => 'NO_PANTS_ARMOR',
   chr(0) => 'NO_BOOTS_ARMOR',
);

our %ServerCommandsByID = (
   chr(0) => 'RAW_TEXT',
   chr(1) => 'MOVE_TO',
   chr(2) => 'SEND_PM',
   chr(5) => 'GET_PLAYER_INFO',
   chr(6) => 'RUN_TO',
   chr(7) => 'SIT_DOWN',
   chr(8) => 'SEND_ME_MY_ACTORS',
   chr(9) => 'SEND_OPENING_SCREEN',
   chr(10) => 'SEND_VERSION',
   chr(11) => 'TURN_LEFT',
   chr(12) => 'TURN_RIGHT',
   chr(13) => 'PING',
   chr(14) => 'HEART_BEAT',
   chr(15) => 'LOCATE_ME',
   chr(16) => 'USE_MAP_OBJECT',
   chr(17) => 'SEND_MY_STATS',
   chr(18) => 'SEND_MY_INVENTORY',
   chr(19) => 'LOOK_AT_INVENTORY_ITEM',
   chr(20) => 'MOVE_INVENTORY_ITEM',
   chr(21) => 'HARVEST',
   chr(22) => 'DROP_ITEM',
   chr(23) => 'PICK_UP_ITEM',
   chr(24) => 'LOOK_AT_GROUND_ITEM',
   chr(25) => 'INSPECT_BAG',
   chr(26) => 'S_CLOSE_BAG',
   chr(27) => 'LOOK_AT_MAP_OBJECT',
   chr(28) => 'TOUCH_PLAYER',
   chr(29) => 'RESPOND_TO_NPC',
   chr(30) => 'MANUFACTURE_THIS',
   chr(31) => 'USE_INVENTORY_ITEM',
   chr(32) => 'TRADE_WITH',
   chr(33) => 'ACCEPT_TRADE',
   chr(34) => 'REJECT_TRADE',
   chr(35) => 'EXIT_TRADE',
   chr(36) => 'PUT_OBJECT_ON_TRADE',
   chr(37) => 'REMOVE_OBJECT_FROM_TRADE',
   chr(38) => 'LOOK_AT_TRADE_ITEM',
   chr(39) => 'CAST_SPELL',
   chr(40) => 'ATTACK_SOMEONE',
   chr(41) => 'GET_KNOWLEDGE_INFO',
   chr(42) => 'ITEM_ON_ITEM',
   chr(43) => 'SEND_BOOK',
   chr(44) => 'GET_STORAGE_CATEGORY',
   chr(45) => 'DEPOSITE_ITEM',
   chr(46) => 'WITHDRAW_ITEM',
   chr(47) => 'LOOK_AT_STORAGE_ITEM',
   chr(48) => 'SPELL_NAME',
   chr(60) => 'PING_RESPONSE',
   chr(61) => 'SET_ACTIVE_CHANNEL',
   chr(140) => 'LOG_IN',
   chr(141) => 'CREATE_CHAR',
   chr(230) => 'GET_DATE',
   chr(231) => 'GET_TIME',
   chr(232) => 'SERVER_STATS',
   chr(233) => 'ORIGINAL_IP',
   chr(255) => 'BYE',
);

# I Hypothesise that if the client sends
# one of these commands the server will
# cancel the current moevement
our %ActiveCommands = (
   chr(1) => 'MOVE_TO',
   chr(6) => 'RUN_TO',
   chr(7) => 'SIT_DOWN',
   chr(11) => 'TURN_LEFT',
   chr(12) => 'TURN_RIGHT',
   chr(21) => 'HARVEST',
   chr(22) => 'DROP_ITEM',
   chr(23) => 'PICK_UP_ITEM',
   chr(24) => 'LOOK_AT_GROUND_ITEM',
   chr(25) => 'INSPECT_BAG',
   chr(26) => 'S_CLOSE_BAG',
   chr(27) => 'LOOK_AT_MAP_OBJECT',
   chr(28) => 'TOUCH_PLAYER',
   chr(29) => 'RESPOND_TO_NPC',
   chr(30) => 'MANUFACTURE_THIS',
   chr(31) => 'USE_INVENTORY_ITEM',
   chr(32) => 'TRADE_WITH',
   chr(33) => 'ACCEPT_TRADE',
   chr(34) => 'REJECT_TRADE',
   chr(35) => 'EXIT_TRADE',
   chr(36) => 'PUT_OBJECT_ON_TRADE',
   chr(37) => 'REMOVE_OBJECT_FROM_TRADE',
   chr(38) => 'LOOK_AT_TRADE_ITEM',
   chr(39) => 'CAST_SPELL',
   chr(40) => 'ATTACK_SOMEONE',
   chr(42) => 'ITEM_ON_ITEM',
   chr(44) => 'GET_STORAGE_CATEGORY',
   chr(45) => 'DEPOSITE_ITEM',
   chr(46) => 'WITHDRAW_ITEM',
   chr(47) => 'LOOK_AT_STORAGE_ITEM',
);

our %ELStatsByID = (
   chr(0) => 'PHY_CUR',
   chr(1) => 'PHY_BASE',
   chr(2) => 'COO_CUR',
   chr(3) => 'COO_BASE',
   chr(4) => 'REAS_CUR',
   chr(5) => 'REAS_BASE',
   chr(6) => 'WILL_CUR',
   chr(7) => 'WILL_BASE',
   chr(8) => 'INST_CUR',
   chr(9) => 'INST_BASE',
   chr(10) => 'VIT_CUR',
   chr(11) => 'VIT_BASE',
   chr(12) => 'HUMAN_CUR',
   chr(13) => 'HUMAN_BASE',
   chr(14) => 'ANIMAL_CUR',
   chr(15) => 'ANIMAL_BASE',
   chr(16) => 'VEGETAL_CUR',
   chr(17) => 'VEGETAL_BASE',
   chr(18) => 'INORG_CUR',
   chr(19) => 'INORG_BASE',
   chr(20) => 'ARTIF_CUR',
   chr(21) => 'ARTIF_BASE',
   chr(22) => 'MAGIC_CUR',
   chr(23) => 'MAGIC_BASE',
   chr(24) => 'MAN_S_CUR',
   chr(25) => 'MAN_S_BASE',
   chr(26) => 'HARV_S_CUR',
   chr(27) => 'HARV_S_BASE',
   chr(28) => 'ALCH_S_CUR',
   chr(29) => 'ALCH_S_BASE',
   chr(30) => 'OVRL_S_CUR',
   chr(31) => 'OVRL_S_BASE',
   chr(32) => 'DEF_S_CUR',
   chr(33) => 'DEF_S_BASE',
   chr(34) => 'ATT_S_CUR',
   chr(35) => 'ATT_S_BASE',
   chr(36) => 'MAG_S_CUR',
   chr(37) => 'MAG_S_BASE',
   chr(38) => 'POT_S_CUR',
   chr(39) => 'POT_S_BASE',
   chr(40) => 'CARRY_WGHT_CUR',
   chr(41) => 'CARRY_WGHT_BASE',
   chr(42) => 'MAT_POINT_CUR',
   chr(43) => 'MAT_POINT_BASE',
   chr(44) => 'ETH_POINT_CUR',
   chr(45) => 'ETH_POINT_BASE',
   chr(46) => 'FOOD_LEV',
   chr(47) => 'RESEARCHING',
   chr(48) => 'MAG_RES',
   chr(49) => 'MAN_EXP',
   chr(50) => 'MAN_EXP_NEXT',
   chr(51) => 'HARV_EXP',
   chr(52) => 'HARV_EXP_NEXT',
   chr(53) => 'ALCH_EXP',
   chr(54) => 'ALCH_EXP_NEXT',
   chr(55) => 'OVRL_EXP',
   chr(56) => 'OVRL_EXP_NEXT',
   chr(57) => 'DEF_EXP',
   chr(58) => 'DEF_EXP_NEXT',
   chr(59) => 'ATT_EXP',
   chr(60) => 'ATT_EXP_NEXT',
   chr(61) => 'MAG_EXP',
   chr(62) => 'MAG_EXP_NEXT',
   chr(63) => 'POT_EXP',
   chr(64) => 'POT_EXP_NEXT',
   chr(65) => 'RESEARCH_COMPLETED',
   chr(66) => 'RESEARCH_TOTAL',
   chr(67) => 'SUM_EXP',
   chr(68) => 'SUM_EXP_NEXT',
   chr(69) => 'SUM_S_CUR',
   chr(70) => 'SUM_S_BASE',
   chr(71) => 'CRA_EXP',
   chr(72) => 'CRA_EXP_NEXT',
   chr(73) => 'CRA_S_CUR',
   chr(74) => 'CRA_S_BASE',
);

our %FramesByID = (
   chr(0) => 'frame_walk',
   chr(1) => 'frame_run',
   chr(2) => 'frame_die1',
   chr(3) => 'frame_die2',
   chr(4) => 'frame_pain1',
   chr(5) => 'frame_pick',
   chr(6) => 'frame_drop',
   chr(7) => 'frame_idle',
   chr(8) => 'frame_harvest',
   chr(9) => 'frame_cast',
   chr(10) => 'frame_ranged',
   chr(11) => 'frame_pain2',
   chr(12) => 'frame_sit',
   chr(13) => 'frame_stand',
   chr(14) => 'frame_sit_idle',
   chr(15) => 'frame_combat_idle',
   chr(16) => 'frame_in_combat',
   chr(17) => 'frame_out_combat',
   chr(18) => 'frame_attack_up_1',
   chr(19) => 'frame_attack_up_2',
   chr(20) => 'frame_attack_up_3',
   chr(21) => 'frame_attack_up_4',
   chr(22) => 'frame_attack_down_1',
   chr(23) => 'frame_attack_down_2',
);

our %ActorTypesByID = (
   chr(0) => 'human_female',
   chr(1) => 'human_male',
   chr(2) => 'elf_female',
   chr(3) => 'elf_male',
   chr(4) => 'dwarf_female',
   chr(5) => 'dwarf_male',
   chr(6) => 'wraith',
   chr(7) => 'cyclops',
   chr(8) => 'beaver',
   chr(9) => 'rat',
   chr(10) => 'goblin_male_2',
   chr(11) => 'goblin_female_1',
   chr(12) => 'town_folk4',
   chr(13) => 'town_folk5',
   chr(14) => 'shop_girl3',
   chr(15) => 'deer',
   chr(16) => 'bear',
   chr(17) => 'wolf',
   chr(18) => 'white_rabbit',
   chr(19) => 'brown_rabbit',
   chr(20) => 'boar',
   chr(21) => 'bear2',
   chr(22) => 'snake1',
   chr(23) => 'snake2',
   chr(24) => 'snake3',
   chr(25) => 'fox',
   chr(26) => 'puma',
   chr(27) => 'ogre_male_1',
   chr(28) => 'goblin_male_1',
   chr(29) => 'orc_male_1',
   chr(30) => 'orc_female_1',
   chr(31) => 'skeleton',
   chr(32) => 'gargoyle1',
   chr(33) => 'gargoyle2',
   chr(34) => 'gargoyle3',
   chr(35) => 'troll',
   chr(36) => 'chimeran_wolf_mountain',
   chr(37) => 'gnome_female',
   chr(38) => 'gnome_male',
   chr(39) => 'orchan_female',
   chr(40) => 'orchan_male',
   chr(41) => 'draegoni_female',
   chr(42) => 'draegoni_male',
   chr(43) => 'skunk_1',
   chr(44) => 'racoon_1',
   chr(45) => 'unicorn_1',
   chr(46) => 'chimeran_wolf_desert',
   chr(47) => 'chimeran_wolf_forest',
   chr(48) => 'bear_3',
   chr(49) => 'bear_4',
   chr(50) => 'panther',
   chr(51) => 'feran',
   chr(52) => 'leopard_1',
   chr(53) => 'leopard_2',
   chr(54) => 'chimeran_wolf_arctic',
   chr(55) => 'tiger_1',
   chr(56) => 'tiger_2',
   chr(57) => 'armed_female_orc',
   chr(58) => 'armed_male_orc',
   chr(59) => 'armed_skeleton',
   chr(60) => 'phantom_warrior',
   chr(61) => 'imp',
   chr(62) => 'brownie',
   chr(63) => 'leprechaun',
   chr(64) => 'spider_s_1',
   chr(65) => 'spider_s_2',
   chr(66) => 'spider_s_3',
   chr(67) => 'spider_l_1',
   chr(68) => 'spider_l_2',
   chr(69) => 'spider_l_3',
   chr(70) => 'wood_sprite',
   chr(71) => 'spider_l_4',
   chr(72) => 'spider_s_4',
   chr(73) => 'giant_1',
   chr(74) => 'hobgoblin',
   chr(75) => 'yeti',
   chr(76) => 'snake4',
);

our %WeaponsByID = (
   chr(0) => 'WEAPON_NONE',
   chr(1) => 'SWORD_1',
   chr(2) => 'SWORD_2',
   chr(3) => 'SWORD_3',
   chr(4) => 'SWORD_4',
   chr(5) => 'SWORD_5',
   chr(6) => 'SWORD_6',
   chr(7) => 'SWORD_7',
   chr(8) => 'STAFF_1',
   chr(9) => 'STAFF_2',
   chr(10) => 'STAFF_3',
   chr(11) => 'STAFF_4',
   chr(12) => 'HAMMER_1',
   chr(13) => 'HAMMER_2',
   chr(14) => 'PICKAX',
   chr(15) => 'SWORD_1_FIRE',
   chr(16) => 'SWORD_2_FIRE',
   chr(17) => 'SWORD_2_COLD',
   chr(18) => 'SWORD_3_FIRE',
   chr(19) => 'SWORD_3_COLD',
   chr(20) => 'SWORD_3_MAGIC',
   chr(21) => 'SWORD_4_FIRE',
   chr(22) => 'SWORD_4_COLD',
   chr(23) => 'SWORD_4_MAGIC',
   chr(24) => 'SWORD_4_THERMAL',
   chr(25) => 'SWORD_5_FIRE',
   chr(26) => 'SWORD_5_COLD',
   chr(27) => 'SWORD_5_MAGIC',
   chr(28) => 'SWORD_5_THERMAL',
   chr(29) => 'SWORD_6_FIRE',
   chr(30) => 'SWORD_6_COLD',
   chr(31) => 'SWORD_6_MAGIC',
   chr(32) => 'SWORD_6_THERMAL',
   chr(33) => 'SWORD_7_FIRE',
   chr(34) => 'SWORD_7_COLD',
   chr(35) => 'SWORD_7_MAGIC',
   chr(36) => 'SWORD_7_THERMAL',
   chr(37) => 'PICKAX_MAGIC',
   chr(38) => 'BATTLEAXE_IRON',
   chr(39) => 'BATTLEAXE_STEEL',
   chr(40) => 'BATTLEAXE_TITANIUM',
   chr(41) => 'BATTLEAXE_IRON_FIRE',
   chr(42) => 'BATTLEAXE_STEEL_COLD',
   chr(43) => 'BATTLEAXE_STEEL_FIRE',
   chr(44) => 'BATTLEAXE_TITANIUM_COLD',
   chr(45) => 'BATTLEAXE_TITANIUM_FIRE',
   chr(46) => 'BATTLEAXE_TITANIUM_MAGIC',
   chr(47) => 'GLOVE_FUR',
   chr(48) => 'GLOVE_LEATHER',
   chr(49) => 'BONE_1',
   chr(50) => 'STICK_1',
   chr(51) => 'SWORD_EMERALD_CLAYMORE',
   chr(52) => 'SWORD_CUTLASS',
   chr(53) => 'SWORD_SUNBREAKER',
   chr(54) => 'SWORD_ORC_SLAYER',
   chr(55) => 'SWORD_EAGLE_WING',
   chr(56) => 'SWORD_RAPIER',
   chr(57) => 'SWORD_JAGGED_SABER',
);

our %PantsColorsByID = (
   chr(0) => 'PANTS_BLACK',
   chr(1) => 'PANTS_BLUE',
   chr(2) => 'PANTS_BROWN',
   chr(3) => 'PANTS_DARKBROWN',
   chr(4) => 'PANTS_GREY',
   chr(5) => 'PANTS_GREEN',
   chr(6) => 'PANTS_LIGHTBROWN',
   chr(7) => 'PANTS_RED',
   chr(8) => 'PANTS_WHITE',
   chr(9) => 'PANTS_LEATHER',
   chr(10) => 'PANTS_IRON_CUISSES',
   chr(11) => 'PANTS_FUR',
   chr(12) => 'PANTS_STEEL_CUISSES',
   chr(13) => 'PANTS_TITANIUM_CUISSES',
   chr(14) => 'PANTS_HYDROGENIUM_CUISSES',
);

our %WindowsByID = (
   chr(1) => 'RULE_WIN',
   chr(2) => 'RULE_INTERFACE',
   chr(3) => 'NEW_CHAR_INTERFACE',
);

our %ActorCommandsByID = (
   chr(0) => 'nothing',
   chr(1) => 'kill_me',
   chr(3) => 'die1',
   chr(4) => 'die2',
   chr(5) => 'pain1',
   chr(6) => 'pick',
   chr(7) => 'drop',
   chr(8) => 'idle',
   chr(9) => 'harvest',
   chr(10) => 'cast',
   chr(11) => 'ranged',
   chr(12) => 'meele',
   chr(13) => 'sit_down',
   chr(14) => 'stand_up',
   chr(15) => 'turn_left',
   chr(16) => 'turn_right',
   chr(17) => 'pain2',
   chr(18) => 'enter_combat',
   chr(19) => 'leave_combat',
   chr(20) => 'move_n',
   chr(21) => 'move_ne',
   chr(22) => 'move_e',
   chr(23) => 'move_se',
   chr(24) => 'move_s',
   chr(25) => 'move_sw',
   chr(26) => 'move_w',
   chr(27) => 'move_nw',
   chr(30) => 'run_n',
   chr(31) => 'run_ne',
   chr(32) => 'run_e',
   chr(33) => 'run_se',
   chr(34) => 'run_s',
   chr(35) => 'run_sw',
   chr(36) => 'run_w',
   chr(37) => 'run_nw',
   chr(38) => 'turn_n',
   chr(39) => 'turn_ne',
   chr(40) => 'turn_e',
   chr(41) => 'turn_se',
   chr(42) => 'turn_s',
   chr(43) => 'turn_sw',
   chr(44) => 'turn_w',
   chr(45) => 'turn_nw',
   chr(46) => 'attack_up_1',
   chr(47) => 'attack_up_2',
   chr(48) => 'attack_up_3',
   chr(49) => 'attack_up_4',
   chr(50) => 'attack_down_1',
   chr(51) => 'attack_down_2',
);

our %BootsColorsByID = (
   chr(0) => 'BOOTS_BLACK',
   chr(1) => 'BOOTS_BROWN',
   chr(2) => 'BOOTS_DARKBROWN',
   chr(3) => 'BOOTS_DULLBROWN',
   chr(4) => 'BOOTS_LIGHTBROWN',
   chr(5) => 'BOOTS_ORANGE',
   chr(6) => 'BOOTS_LEATHER',
   chr(7) => 'BOOTS_FUR',
   chr(8) => 'BOOTS_IRON_GREAVE',
   chr(9) => 'BOOTS_STEEL_GREAVE',
   chr(10) => 'BOOTS_TITANIUM_GREAVE',
   chr(11) => 'BOOTS_HYDROGENIUM_GREAVE',
);

our %SoundByID = (
   chr(0) => 'snd_rain',
   chr(1) => 'snd_tele_in',
   chr(2) => 'snd_tele_out',
   chr(3) => 'snd_teleprtr',
   chr(4) => 'snd_thndr_1',
   chr(5) => 'snd_thndr_2',
   chr(6) => 'snd_thndr_3',
   chr(7) => 'snd_thndr_4',
   chr(8) => 'snd_thndr_5',
   chr(9) => 'snd_fire',
);


our %ColorsByID = (
   chr(0) => 'c_lbound',
   chr(0) => 'c_red1',
   chr(1) => 'c_orange1',
   chr(2) => 'c_yellow1',
   chr(3) => 'c_green1',
   chr(4) => 'c_blue1',
   chr(5) => 'c_purple1',
   chr(6) => 'c_grey1',
   chr(7) => 'c_red2',
   chr(8) => 'c_orange2',
   chr(9) => 'c_yellow2',
   chr(10) => 'c_green2',
   chr(11) => 'c_blue2',
   chr(12) => 'c_purple2',
   chr(13) => 'c_grey2',
   chr(14) => 'c_red3',
   chr(15) => 'c_orange3',
   chr(16) => 'c_yellow3',
   chr(17) => 'c_green3',
   chr(18) => 'c_blue3',
   chr(19) => 'c_purple3',
   chr(20) => 'c_grey3',
   chr(21) => 'c_red4',
   chr(22) => 'c_orange4',
   chr(23) => 'c_yellow4',
   chr(24) => 'c_green4',
   chr(25) => 'c_blue4',
   chr(26) => 'c_purple4',
   chr(27) => 'c_ubound',
   chr(27) => 'c_grey4',
);

our %ShirtColorsByID = (
   chr(0) => 'SHIRT_BLACK',
   chr(1) => 'SHIRT_BLUE',
   chr(2) => 'SHIRT_BROWN',
   chr(3) => 'SHIRT_GREY',
   chr(4) => 'SHIRT_GREEN',
   chr(5) => 'SHIRT_LIGHTBROWN',
   chr(6) => 'SHIRT_ORANGE',
   chr(7) => 'SHIRT_PINK',
   chr(8) => 'SHIRT_PURPLE',
   chr(9) => 'SHIRT_RED',
   chr(10) => 'SHIRT_WHITE',
   chr(11) => 'SHIRT_YELLOW',
   chr(12) => 'SHIRT_LEATHER_ARMOR',
   chr(13) => 'SHIRT_CHAIN_ARMOR',
   chr(14) => 'SHIRT_STEEL_CHAIN_ARMOR',
   chr(15) => 'SHIRT_TITANIUM_CHAIN_ARMOR',
   chr(16) => 'SHIRT_IRON_PLATE_ARMOR',
   chr(17) => 'SHIRT_ARMOR_6',
   chr(18) => 'SHIRT_FUR',
   chr(19) => 'SHIRT_STEEL_PLATE_ARMOR',
   chr(20) => 'SHIRT_TITANIUM_PLATE_ARMOR',
);

our %HairColorsByID = (
   chr(0) => 'HAIR_BLACK',
   chr(1) => 'HAIR_BLOND',
   chr(2) => 'HAIR_BROWN',
   chr(3) => 'HAIR_GRAY',
   chr(4) => 'HAIR_RED',
   chr(5) => 'HAIR_WHITE',
   chr(6) => 'HAIR_BLUE',
   chr(7) => 'HAIR_GREEN',
   chr(8) => 'HAIR_PURPLE',
);

our %ShieldsByID = (
   chr(0) => 'SHIELD_WOOD',
   chr(1) => 'SHIELD_WOOD_ENHANCED',
   chr(2) => 'SHIELD_IRON',
   chr(3) => 'SHIELD_STEEL',
   chr(4) => 'SHIELD_TITANIUM',
   chr(5) => 'SHIELD_HYDROGENIUM',
   chr(11) => 'SHIELD_NONE',
);
